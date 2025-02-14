defmodule Phoenix.React.Runtime do
  @moduledoc """
  Phoenix.React.Runtime

  Manage the runtime of the React Render Server

  If in dev mode, it will start a file watcher to watch the component directory.
  Reload the server when the component file changed with a throttle time at `3s`.

  @behaviour Phoenix.React.Runtime

  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_runtime(runtime, args) do
    spec = {runtime, args}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def start_file_watcher(args) do
    spec = {Phoenix.React.Runtime.FileWatcher, args}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  defstruct [:component_base, :port, :server_js, :cd, render_timeout: 300_000]

  @type t :: %__MODULE__{
          render_timeout: integer(),
          component_base: path(),
          server_js: path(),
          cd: path(),
          port: port()
        }

  @type path :: binary()

  @type component :: binary()

  @type html :: binary()

  @callback start([{:component_base, path()}, {:render_timeout, integer()}]) :: port()

  @callback start_file_watcher(path()) :: :ok

  @callback config() :: list()

  @callback render_to_readable_stream(component(), map(), GenServer.from(), t()) ::
              {:reply, {:ok, html()}, t()} | {:reply, {:error, term()}, t()}

  @callback render_to_string(component(), map(), GenServer.from(), t()) ::
              {:reply, {:ok, html()}, t()} | {:reply, {:error, term()}, t()}

  @callback render_to_static_markup(component(), map(), GenServer.from(), t()) ::
              {:reply, {:ok, html()}, t()} | {:reply, {:error, term()}, t()}

  defmacro __using__(_) do
    quote do
      @behaviour Phoenix.React.Runtime
      alias Phoenix.React.Runtime

      use GenServer

      @impl true
      def handle_call({method, component, props}, from, state)
          when method in [:render_to_readable_stream, :render_to_string, :render_to_static_markup] do
        apply(__MODULE__, method, [component, props, from, state])
      end
    end
  end
end
