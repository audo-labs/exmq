use Mix.Config

config :exmq, Exmq,
  amqp: [host: "localhost"],
  root_topic: "audo"

case Mix.env do
  :test -> import_config "test.exs"
  _ -> nil
end
