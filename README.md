# Phoenix.React

[![release](https://github.com/gsmlg-dev/phoenix-react/actions/workflows/test-and-release.yml/badge.svg)](https://github.com/gsmlg-dev/phoenix-react/actions/workflows/test-and-release.yml)

Run a `react` render server to render react component in `Phoenix` html.

**Features**

- Render to static markup
- Render to html
- Render to html and use hydrate at client side by `live_view` `hook`

See the [docs](https://hexdocs.pm/phoenix_react_server/) for more information.

## Install this package

Add deps in `mix.exs`

```elixir
    {:phoenix_react_server, "~> 0.1.0"},
```

## Configuration

Set config, runtime, react components, etc.

```elixir
import Config

config :phoenix_react_server, Phoenix.React,
  # runtime: Path.expand("../node_modules/@babel/node/bin/babel-node.js", __DIR__)
  # runtime: System.find_executable("deno"),
  runtime: System.find_executable("bun"),
  components_base: Path.expand("../assets/js", __DIR__),
  cache_ttl: 3600
```

Add Render Server in your application Supervisor tree.

```elixir
  def start(_type, _args) do
    children = [
      ReactDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:react_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ReactDemo.PubSub},
      # React render service
      Phoenix.React.Superviser,
      ReactDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReactDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

Write React Component Module

```elixir
defmodule ReactDemoWeb.ReactComponents do
  use Phoenix.Component
  use Phoenix.React.Helper

  def markdown(assigns) do
    props = assigns.props

    # path: components_base + "components/markdown.js"
    react_component("components/markdown.js", props)
  end
end
```

Import in html helpers

```elixir
  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: ReactDemoWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import ReactDemoWeb.CoreComponents
      import ReactDemoWeb.ReactComponents

      ...
    end
  end
```

Use in html template

```heex
  <.markdown
    props={%{
      content: """
      # Hello World
      
      Best in the world!

      ```elixir
      defmodule Hello do
        def world do
          IO.puts "Hello World"
        end
      end
      ```
      
      """
    }}
  />
```

## Example App

An example can be find in `react_demo` folder.
