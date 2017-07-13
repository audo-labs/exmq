defmodule Exmq do
  use Application
  use AMQP

  import Exmq.Config, only: [config: 1]

  unless Application.get_env(:exmq, Exmq) do
    raise "Exmq is not configured"
  end

  unless  Keyword.get(Application.get_env(:exmq, Exmq), :handler) do
    raise "Exmq requires a handler"
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Exmq.Server, [])
    ]

    opts = [strategy: :one_for_one, name: Exmq.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def send(queue, msg) do
    queue = "#{config(:root)}.#{queue}"
    opts = config(:amqp) || []
    root = config(:root)
    {:ok, connection} = Connection.open(opts)
    {:ok, channel} = Channel.open(connection)
    exchange = "#{root}-exchange"
    Exchange.topic(channel, exchange, durable: true)
    #Queue.declare(channel, queue, durable: true)
    Queue.declare(channel, queue, durable: true,
                  arguments: [{"x-dead-letter-exchange", :longstr, ""},
                              {"x-dead-letter-routing-key", :longstr, "test.errors"}])
    Queue.bind(channel, queue, exchange)
    Basic.publish(channel, "", queue, msg, persistent: true)

    handler().on_send(msg)

    Connection.close(connection)
  end

  def handler do
    config(:handler)
  end
end
