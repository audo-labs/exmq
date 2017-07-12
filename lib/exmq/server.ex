defmodule Exmq.Server do
  use GenServer

  import Exmq.Config, only: [config: 1]

  alias AMQP.Connection
  alias AMQP.Queue
  alias AMQP.Basic
  alias AMQP.Channel
  alias AMQP.Exchange

  require Logger

  @queues config(:queues) || []
  @amqp_opts config(:amqp) || []
  @root config(:root)
  @error "#{@root}.errors"
  @exchange "#{@root}-exchange"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    rabbitmq_connect()
  end

  def handle_call(:agent, _from, [h|t]) do
    {:reply, :ok, h, t}
  end

  def handle_cast(payload, state) do
    Exmq.handler().on_receive(payload)

    {:noreply, :ok, [payload | state]}
  end

  def wait_for_messages do
    receive do
      {:basic_deliver, payload, meta} ->
        message = %{queue: meta.routing_key, payload: payload}
        GenServer.cast(__MODULE__, message)
        wait_for_messages()
    end
  end

  defp rabbitmq_connect do
    case Connection.open(@amqp_opts) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)
        # Everything else remains the same
        {:ok, chan} = Channel.open(conn)
        Basic.qos(chan, prefetch_count: 10)
        Exchange.topic(chan, @exchange, durable: true)
        Queue.declare(chan, @error, durable: true)

        for queue <- Enum.map(@queues, &"#{@root}.#{&1}") do
          Queue.declare(chan, queue, durable: true,
                        arguments: [{"x-dead-letter-exchange", :longstr, ""},
                                    {"x-dead-letter-routing-key", :longstr, @error}])
          {:ok, pid} = Task.start_link(&wait_for_messages/0)
          :global.register_name(:receiver, pid)
          Basic.consume(chan, queue, pid, no_ack: true)
          Queue.bind(chan, queue, @exchange)
        end
        {:ok, chan}
      {:error, err} ->
        Logger.error("Exmq: can't connect to rabbitmq broker: #{inspect err}")
        # Reconnection loop
        :timer.sleep(10000)
        rabbitmq_connect()
    end
  end

  # 2. Implement a callback to handle DOWN notifications from the system
  #    This callback should try to reconnect to the server
  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = rabbitmq_connect()
    {:noreply, chan}
  end
end
