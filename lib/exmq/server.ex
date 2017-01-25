defmodule Exmq.Server do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    Logger.debug("start_link called with #{opts}")
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Queue.declare(channel, "hello")
    IO.puts " [*] Waiting for messages. To exit press CTRL+C, CTRL+C"

    {:ok, pid} = Task.start_link(fn -> wait_for_messages end)
    :global.register_name(:receiver, pid)

    AMQP.Basic.consume(channel, "hello", pid, no_ack: true)

    {:ok, []}
  end

  def handle_call(:agent, _from, []) do
    Logger.debug("received!")
    {:reply, :ok, []}
  end

  def wait_for_messages do
    receive do
      {:basic_deliver, payload, _meta} ->
        IO.puts " [x] Received #{payload}"
        GenServer.call(__MODULE__, :agent)
        wait_for_messages
    end
  end
end
