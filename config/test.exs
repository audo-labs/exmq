use Mix.Config

IO.puts "Loading config for default test env"

config :exmq, Exmq,
  queues: ["queue1", "queue2"],
  handler: Exmq.LoggerHandler,
  amqp_env: [host: {:system, "HOST"}]
