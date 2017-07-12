defmodule Exmq do
  use Application

  unless Application.get_env(:exmq, Exmq) do
    raise "Exmq is not configured"
  end

  unless  Keyword.get(Application.get_env(:exmq, Exmq), :handler) do
    raise "Exmq requires a handler"
  end

  def config(), do: Application.get_env(:exmq, Exmq)

  def config(key) do
    case config() |> Keyword.get(key) do
      {:system, value} ->
        System.get_env(value)
      data ->
        if is_list(data) do
          for e <- data do
            case e do
              {k, {:system, value}} ->
                {k, System.get_env(value)}
              _ ->
                e
            end
          end
        else
          data
        end
    end
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
    {:ok, connection} = AMQP.Connection.open(opts)
    {:ok, channel} = AMQP.Channel.open(connection)
    exchange = "#{root}-exchange"
    AMQP.Exchange.topic(channel, exchange, durable: true)
    #AMQP.Queue.declare(channel, queue, durable: true)
    AMQP.Queue.declare(channel, queue, durable: true,
                  arguments: [{"x-dead-letter-exchange", :longstr, ""},
                              {"x-dead-letter-routing-key", :longstr, "test.errors"}])
    AMQP.Queue.bind(channel, queue, exchange)
    AMQP.Basic.publish(channel, "", queue, msg, persistent: true)

    handler().on_send(msg)

    AMQP.Connection.close(connection)
  end

  def handler do
    config(:handler)
  end
end
