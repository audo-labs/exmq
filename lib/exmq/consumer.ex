defmodule Exmq.Consumer do

  @callback handle_message({message :: term, meta :: term}, state :: term) ::
    {:ok | state :: term}

  defmacro __using__(opts) do
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

      def init(opts) do
        Exmq.Bus.consume(opts[:topic], self())
        {:ok, opts}
      end

      # Confirmation sent by the broker after registering this process as a consumer
      def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
        {:noreply, chan}
      end

      def handle_info({:basic_deliver, message, meta}, state) do
        handle_message({message, meta}, state)
        {:noreply, state}
      end

      def handle_message({message, meta}, state) do
        {:ok, state}
      end

      defoverridable handle_message: 2

    end
  end

end
