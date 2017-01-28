defmodule Exmq.Server do
  use GenServer

  import Exmq, only: [config: 1]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    opts = config(:amqp) || []
    queue = config(:queue)

    {:ok, connection} = AMQP.Connection.open(opts)
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Queue.declare(channel, queue)

    {:ok, pid} = Task.start_link(fn -> wait_for_messages end)
    :global.register_name(:receiver, pid)

    AMQP.Basic.consume(channel, queue, pid, no_ack: true)

    {:ok, []}
  end

  def handle_call(:agent, _from, [h|t]) do
    {:reply, :ok, h, t}
  end

  def handle_cast(payload, state) do
    handler = config(:handler)
    handler.on_receive(payload)

    {:noreply, :ok, [payload | state]}
  end

  def wait_for_messages do
    receive do
      {:basic_deliver, payload, _meta} ->
        GenServer.cast(__MODULE__, payload)
        wait_for_messages
    end
  end
end
