defmodule Exmq.Bus do
  use GenServer
  use AMQP

  import Exmq.Config, only: [config: 1]
  require Logger

  @amqp_opts config(:amqp) || []
  @root config(:root)
  @errors "#{config(:root)}.errors"
  @exchange "#{@root}-exchange"

  #
  # Client API
  #

  def send(topic, message) do
    GenServer.cast(__MODULE__, {:send, topic, message})
  end

  def consume(topic, pid) do
    GenServer.cast(__MODULE__, {:consume, topic, pid})
  end

  def pid do
    GenServer.whereis(__MODULE__)
  end

  #
  # Server API
  #

  def handle_cast({:consume, topic, pid}, state) do
    topic = "#{@root}.#{topic}"
    Queue.declare(state[:channel], @errors, durable: true)
    {:ok, %{queue: queue}} = 
      Queue.declare(state[:channel], "", 
                    durable: true,
                    exclusive: true, 
                    arguments: [
                      {"x-dead-letter-exchange", :longstr, ""},
                      {"x-dead-letter-routing-key", :longstr, @errors}])
    Queue.bind(state[:channel], queue, @exchange, routing_key: topic)
    Basic.consume(state[:channel], queue, pid, no_ack: true)
    {:noreply, state}
  end

  def handle_cast({:send, topic, message}, state) do
    IO.inspect(state[:channel])
    topic = "#{@root}.#{topic}"
    IO.inspect(topic)
    Basic.publish(state[:channel], @exchange, topic, message, persistent: true)
    {:noreply, state}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      Keyword.merge(opts, [connected: false, channel: nil]),
      name: __MODULE__
    )
  end

  def init(state) do
    connect(state)
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, state) do
    {:ok, state} = reconnect(state)
    {:noreply, state}
  end

  def handle_info(:reconnect, state) do
    {:ok, state} = reconnect(state)
    {:noreply, state}
  end

  defp connect(state) do
    case Connection.open(@amqp_opts) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:ok, chan} = Channel.open(conn)
        Basic.qos(chan, prefetch_count: 10)
        Exchange.topic(chan, @exchange, durable: true)
        {:ok, Keyword.merge(state, [channel: chan, connected: true])}
      {:error, _} ->
        Process.send_after(self(), :reconnect, 10000)
        {:ok, state}
    end
  end

  defp reconnect(state) do
    connect(Keyword.put(state, :connected, false))
  end

end
