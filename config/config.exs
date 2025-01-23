import Config

config :phoenix_react_server, Phoenix.React,
  # runtime: Path.expand("../node_modules/@babel/node/bin/babel-node.js", __DIR__)
  runtime: System.find_executable("bun"),
  cache_ttl: 3600
