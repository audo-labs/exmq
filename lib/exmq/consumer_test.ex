defmodule Exmq.ConsumerTest do
  use Exmq.Consumer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, Keyword.merge(@opts, opts), name: @name)
  end

  def handle_message({message, meta}, state) do
    IO.puts(">>>> ROOT: #{@name} received #{inspect message}\n#{inspect meta}\n#{inspect state}")
  end

end
