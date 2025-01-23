defmodule ReactDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ReactDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:react_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ReactDemo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ReactDemo.Finch},
      # Start a worker by calling: ReactDemo.Worker.start_link(arg)
      Phoenix.React.Superviser,
      # Start to serve requests, typically the last entry
      ReactDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReactDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ReactDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
