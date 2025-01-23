import Config

config :phoenix_react_server, Phoenix.React,
  runtime: System.find_executable("bun"),
  cache_ttl: 10

config :react_demo, ReactDemoWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4666],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "kmpnmk2HbLCXfguCqhwY4cT0ed5d7cBirQWJXq/MX8/68Y0VakTLJKjNH4dM2IEU",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:react_demo, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:react_demo, ~w(--watch)]}
  ]

config :react_demo, ReactDemoWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/react_demo_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :react_demo, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 200

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  enable_expensive_runtime_checks: true

config :swoosh, :api_client, false
