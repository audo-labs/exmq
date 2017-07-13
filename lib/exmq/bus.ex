defmodule Exmq.Bus do
  use GenServer
  use AMQP

  import Exmq.Config, only: [config: 1]
  require Logger

  @amqp_opts config(:amqp) || []
  @root config(:root)
  @exchange "#{@root}-exchange"

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      Keyword.merge(opts, [connected: false, channel: nil]), name: __MODULE__
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
