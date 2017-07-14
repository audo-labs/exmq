defmodule Exmq.Consumer do
  defmacro __using__(opts) do
    # do something with opts
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer
      use AMQP
      require Logger

      spec = [
        id: opts[:id] || __MODULE__,
        start: Macro.escape(opts[:start]) || quote(do: {__MODULE__, :start_link, [arg]}),
        restart: opts[:restart] || :permanent,
        shutdown: opts[:shutdown] || 5000,
        type: :worker
      ]

      @doc false
      def child_spec(arg) do
        %{unquote_splicing(spec)}
      end

      defoverridable child_spec: 1

      @name spec[:id]
      @opts opts

      # return some code to inject in the caller
      def init(opts) do
        Exmq.Bus.consume(opts[:topic], self())
        {:ok, opts}
      end

      # Confirmation sent by the broker after registering this process as a consumer
      def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
        {:noreply, chan}
      end

      def handle_info({:basic_deliver, message, _meta}, state) do
        IO.inspect("#{@name} received #{message}")
        {:noreply, state}
      end
    end
  end

end
