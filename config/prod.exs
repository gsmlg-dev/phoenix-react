import Config

config :phoenix_react_server, Phoenix.React,
  runtime: Phoenix.React.Runtime.Bun,
  component_base: Path.expand("../priv/react/component", __DIR__),
  cache_ttl: 60 * 15
