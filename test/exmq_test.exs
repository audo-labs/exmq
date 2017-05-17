defmodule ExmqTest do
  use ExUnit.Case
  doctest Exmq

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "load config from env" do
    System.put_env("HOST", "127.0.0.1")
    assert Exmq.config(:amqp_env) == [host: "127.0.0.1"]
  end

  test "load config" do
    assert Exmq.config(:queues) == ["queue1", "queue2"]
  end
end
