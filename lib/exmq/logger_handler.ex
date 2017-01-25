defmodule Exmq.LoggerHandler do
  require Logger

  def on_receive(channel, msg) do
    Logger.info("Exmq.LoggerHandler.on_receive #{msg}")
  end
end
