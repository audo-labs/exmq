defmodule Exmq.Bus do
  use GenServer
  use AMQP

  import Exmq.Config, only: [config: 1]
  require Logger

  @amqp_opts config(:amqp) || []
  @root config(:root)
  @exchange "#{@root}-exchange"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    connect()
  end

  defp connect do
    case Connection.open(@amqp_opts) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:ok, chan} = Channel.open(conn)
        Basic.qos(chan, prefetch_count: 10)
        Exchange.topic(chan, @exchange, durable: true)
        {:ok, chan}
      {:error, err} ->
        :timer.sleep(10000)
        connect()
    end
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = connect()
    {:noreply, chan}
  end

end
