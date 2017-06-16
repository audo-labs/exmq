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


  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(Exmq.Server, [])
      # Starts a worker by calling: Exmq.Worker.start_link(arg1, arg2, arg3)
      # worker(Exmq.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exmq.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def send(queue, msg) do
    opts = config(:amqp) || []
    {:ok, connection} = AMQP.Connection.open(opts)
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Queue.declare(channel, queue, durable: true)
    AMQP.Basic.publish(channel, "", queue, msg, persistent: true)

    handler().on_send(msg)

    AMQP.Connection.close(connection)
  end

  def handler do
    config(:handler)
  end
end
