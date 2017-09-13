use Mix.Config

config :exmq, Exmq,
  amqp: [host: "localhost"],
  root_topic: "exmq"

case Mix.env do
  :test -> import_config "test.exs"
  _ -> nil
end
