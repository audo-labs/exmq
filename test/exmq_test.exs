defmodule ExmqTest do
  use ExUnit.Case

  import Exmq.Config, only: [config: 1]
  doctest Exmq

  setup do
    System.put_env("HOST", "127.0.0.1")
    :ok
  end

  test "load config from env" do
    assert config(:amqp_env) == [host: "127.0.0.1"]
    assert config(:root_topic) == "test"
  end

  test "load config" do
    assert not is_nil(config(:amqp))
  end

  test "send message to test.queue1" do
    assert :ok == Exmq.Bus.send("queue1", "test")
  end
end
