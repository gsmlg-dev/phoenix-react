defmodule Phoenix.React.Superviser do
  @moduledoc """
  The Supervisor of the Phoenix React Server.

  Should add in the application supervisor tree.

  ```
  def start(_type, _args) do
    children = [
      ReactDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:react_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ReactDemo.PubSub},
      # React render service
      Phoenix.React.Superviser,
      ReactDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReactDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Task.Supervisor, name: Pohoenix.React.RenderTaskSupervisr},
      {Phoenix.React.Cache, []},
      {Phoenix.React.Server, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
