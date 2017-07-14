use Mix.Config

IO.puts "Loading config for default test env"

config :exmq, Exmq,
  amqp_env: [host: {:system, "HOST"}],
  root_topic: "test"
