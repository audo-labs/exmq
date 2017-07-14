defmodule Exmq.ConsumerTest2 do
  use Exmq.Consumer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, Keyword.merge(@opts, opts), name: @name)
  end

end
