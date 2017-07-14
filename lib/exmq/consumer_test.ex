defmodule Exmq.ConsumerTest do
  use Exmq.Consumer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, Keyword.merge(@opts, opts), name: @name)
  end

end
