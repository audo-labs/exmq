defmodule ExmqTest do
  use ExUnit.Case
  doctest Exmq

  test "load config from env" do
    System.put_env("HOST", "127.0.0.1")
    assert Exmq.config(:amqp_env) == [host: "127.0.0.1"]
  end

  test "load config" do
    assert Exmq.config(:queues) == ["queue1", "queue2"]
  end

  test "send message to test.queue1" do
    assert :ok == Exmq.send("queue1", "test")
  end
end
