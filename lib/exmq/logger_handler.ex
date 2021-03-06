defmodule Exmq.LoggerHandler do
  require Logger

  def on_receive(msg) do
    Logger.info("Exmq.LoggerHandler.on_receive #{msg.queue} -> #{msg.payload}")
  end

  def on_send(msg) do
    Logger.info("Exmq.LoggerHandler.on_send #{msg}")
  end
end
