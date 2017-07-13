defmodule Exmq.Config do
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
end
