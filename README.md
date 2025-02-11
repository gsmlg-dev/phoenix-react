# Phoenix.React

[![CI](https://github.com/gsmlg-dev/phoenix-react/actions/workflows/ci.yml/badge.svg)](https://github.com/gsmlg-dev/phoenix-react/actions/workflows/ci.yml)

Run a `react` render server to render react component in `Phoenix` html.

**Features**

- [x] Render to static markup
- [x] Render to html
- [x] Hydrate at client side

See the [docs](https://hexdocs.pm/phoenix_react_server/) for more information.

## Install this package

Add deps in `mix.exs`

```elixir
{:phoenix_react_server, "~> 0.3"},
```

## Configuration

Set config, runtime, react components, etc.

```elixir
import Config

config :phoenix_react_server, Phoenix.React,
  # react runtime, default to `bun`
  runtime: Phoenix.React.Runtime.Bun,
  # react component base path
  component_base: Path.expand("../assets/component", __DIR__),
  # cache ttl, default to 60 seconds
  cache_ttl: 60
```

Supported `runtime`

- [x] `Phoenix.React.Runtime.Bun`
- [ ] `Phoenix.React.Runtime.Deno`

Add Render Server in your application Supervisor tree.

```elixir
  def start(_type, _args) do
    children = [
      ReactDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:react_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ReactDemo.PubSub},
      # React render service
      Phoenix.React,
      ReactDemoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ReactDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

Write Phoenix Component use `react_component`

```elixir
defmodule ReactDemoWeb.ReactComponents do
  use Phoenix.Component

  import Phoenix.React.Helper

  def react_markdown(assigns) do
    {static, props} = Map.pop(assigns, :static, true)

    react_component(%{
      component: "markdown",
      props: props,
      static: static
    })
  end
end
```

Import in html helpers in `react_demo_web.ex`

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

## Run in release mode

Bundle components with server.js to one file.

```shell
mix phx.react.bun.bundle --component-base=assets/component --output=priv/react/server.js 
```

Config `runtime` to `Phoenix.React.Runtime.Bun` in `runtime.exs`

```elixir

config :phoenix_react_server, Phoenix.React.Runtime.Bun,
  cmd: System.find_executable("bun"),
  server_js: Path.expand("../priv/react/server.js", __DIR__),
  port: 12666,
  env: :prod
```

## Hydrate at client side

Hydrate react component at client side.

```html
<script type="importmap">
  {
    "imports": {
      "react-dom": "https://esm.run/react-dom@19",
      "app": "https://my.web.site/app.js"
    }
  }
</script>
<script type="module">
import { hydrateRoot } from 'react-dom/client';
import { Component } from 'app';

hydrateRoot(
  document.getElementById('app-wrapper'),
  <App />
);
</script>
```

# DEMO

Path `./react_demo`

