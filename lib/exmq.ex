defmodule Exmq do
  use Application
  use AMQP

  import Exmq.Config, only: [config: 1]

  unless Application.get_env(:exmq, Exmq) do
    raise "Exmq is not configured"
  end

  unless config(:root_topic) do
    raise "Exmq root_topic not defined"
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Exmq.Bus, []),
      worker(Exmq.ConsumerTest, []),
      worker(Exmq.ConsumerTest2, [])
    ]

    opts = [strategy: :one_for_one, name: Exmq.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
