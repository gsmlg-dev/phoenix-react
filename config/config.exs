import Config

config :phoenix_react, Phoenix.React,
  runtime_type: :babel,
  runtime: Path.expand("../node_modules/@babel/node/bin/babel-node.js", __DIR__)
