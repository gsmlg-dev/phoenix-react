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
      {Finch, name: ReactDemo.Finch},
      Phoenix.React,
      ReactDemoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ReactDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ReactDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
