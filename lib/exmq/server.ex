defmodule Exmq.Server do
  use GenServer

  require Logger

  import Exmq, only: [config: 1]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    opts = config(:amqp) || []
    queues = config(:queues) || []

    case AMQP.Connection.open(opts) do
      {:ok, connection} ->
        {:ok, channel} = AMQP.Channel.open(connection)
        for queue <- queues do
          AMQP.Queue.declare(channel, queue)
          {:ok, pid} = Task.start_link(&wait_for_messages/0)
          :global.register_name(:receiver, pid)
          AMQP.Basic.consume(channel, queue, pid, no_ack: true)
        end
        {:ok, []}
      {:error, err} ->
        Logger.error("Exmq: can't connect to rabbitmq broker: #{inspect err}")
        {:ok, []}
    end

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
end
