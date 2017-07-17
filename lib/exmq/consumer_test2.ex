defmodule Exmq.ConsumerTest2 do
  use Exmq.Consumer, topic: "mutation"

  def handle_message({message, meta}, state) do
    IO.puts(">>>> ROOT: #{@name} received #{inspect message}\n#{inspect meta}\n#{inspect state}")
  end

end
