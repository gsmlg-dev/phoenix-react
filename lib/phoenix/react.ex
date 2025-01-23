defmodule Phoenix.React do
  @moduledoc """
  Phoenix.React
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Phoenix.React.Cache, []},
      {Phoenix.React.Server, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end


  @type component :: binary()
  @type props :: map()

  @doc """
  Render a React component to a string by call `renderToString` in `react-dom/server`
  """
  @spec render_to_string(component, props) :: {:ok, binary()} | {:error, term()}
  def render_to_string(component, props \\ %{}) do
    server = find_server_pid()
    timeout = Phoenix.React.Server.config()[:render_timeout]
    GenServer.call(server, {:render_to_string, component, props}, timeout)
  rescue
    error ->
      {:error, error}
  end

  @doc """
  Render a React component to a string by call `renderToStaticMarkup` in `react-dom/server`
  """
  @spec render_to_static_markup(component, props) :: {:ok, binary()} | {:error, term()}
  def render_to_static_markup(component, props) do
    server = find_server_pid()
    timeout = Phoenix.React.Server.config()[:render_timeout]
    GenServer.call(server, {:render_to_static_markup, component, props}, timeout)
  rescue
    error ->
      {:error, error}
  end

  def find_server_pid() do
    # pid = Supervisor.whereis(__MODULE__)
    children = Supervisor.which_children(__MODULE__)
    Enum.find_value(children, fn {_, pid, _, [m | _]} ->
      if m == Phoenix.React.Server do
        pid
      else
        false
      end
    end)
  end
end
