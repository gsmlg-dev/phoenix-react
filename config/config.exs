import Config

config :phoenix_react, Phoenix.React,
  runtime: Path.expand("../node_modules/@babel/node/bin/babel-node.js", __DIR__)
