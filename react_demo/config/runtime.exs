import Config

if System.get_env("PHX_SERVER") do
  config :react_demo, ReactDemoWeb.Endpoint, server: true
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "phoenix-react.com"
  port = String.to_integer(System.get_env("PORT") || "4666")

  config :react_demo, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :react_demo, ReactDemoWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

end
