import Config

config :phoenix_react_server, Phoenix.React,
  runtime: Phoenix.React.Runtime.Bun,
  component_base: Path.expand("../test/fixtures", __DIR__),
  render_timeout: 10_000,
  cache_ttl: 60

config :phoenix_react_server, Phoenix.React.Runtime.Bun, port: 12457
