use Mix.Config

config :exmq, Exmq,
queues: ["queue1", "queue2"],
handler: Exmq.LoggerHandler,
amqp: [host: "localhost"],
root: "exmq"

case Mix.env do
  :test -> import_config "test.exs"
  _ -> nil
end
