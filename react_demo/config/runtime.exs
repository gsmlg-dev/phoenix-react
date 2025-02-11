import Config

config :react_demo, ReactDemoWeb.Endpoint, server: true

if config_env() == :prod do

  host = System.get_env("PHX_HOST") || "phoenix-react.com"
  port = String.to_integer(System.get_env("PORT") || "4666")

  config :react_demo, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :react_demo, ReactDemoWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ]

end
