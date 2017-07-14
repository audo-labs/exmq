defmodule Exmq.Server do
  use GenServer
  use AMQP

  import Exmq.Config, only: [config: 1]

  require Logger

  @root config(:root)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Exmq.Bus.consume(@root, self())
    {:ok, []}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, message, _meta}, state) do
    IO.inspect("#{__MODULE__} received #{message}")
    {:noreply, state}
  end
end
