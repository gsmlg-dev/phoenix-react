# Phoenix.React

[![CI](https://github.com/gsmlg-dev/phoenix-react/actions/workflows/ci.yml/badge.svg)](https://github.com/gsmlg-dev/phoenix-react/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_react_server.svg)](https://hex.pm/packages/phoenix_react_server)
[![Hexdocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/phoenix_react_server/)
[![Hex.pm](https://img.shields.io/hexpm/dt/phoenix_react_server.svg)](https://hex.pm/packages/phoenix_react_server)
[![Hex.pm](https://img.shields.io/hexpm/dw/phoenix_react_server.svg)](https://hex.pm/packages/phoenix_react_server)

Run a `react` render server to render react component in `Phoenix` html.

**Features**

- [x] Render to static markup
- [x] Render to string
- [x] Render to readable stream
- [x] Hydrate at client side
- [x] Connect to Live View render

See the [docs](https://hexdocs.pm/phoenix_react_server/) for more information.

## Install this package

Add deps in `mix.exs`

```elixir
{:phoenix_react_server, "~> 0.5"},
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

### `render_to_static_markup`

Then you can use react server rendered component in Phoenix Component

```html
<div class="card">
  <div clas="card-body">
    <div class="card-title">Hello There</div>
    <.react_markdown
      data={@data}
    >
  </div>
</div>
```

### `render_to_string`

```html
<div class="card w-full">
  <div class="card-body">
    <h3 class="card-title">
      This <code class="text-primary">Table</code> is rendered with <code class="text-secondary">react-dom/server</code>
    </h3>
    <!-- Notice: Remove white space in the react render node or it will break hydrate -->
    <div class="w-full h-full" id="system_usage_container"><.react_system_stats
      data={@data}
    /></div>
  </div>
</div>
```

* Then hydrate on the client.

```js

document.addEventListener('DOMContentLoaded', function() {
  const store = new Store();
  const domContainer = document.querySelector('#system_usage_container');
  if (domContainer) {
    let channel = socket.channel("system_usage:lobby", {});

    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) });


    function Usage(props) {
      const data = useSyncExternalStore(store.subscribe, store.getSnapshot, store.getServerSnapshot);

      return <SystemUsage data={data} />;
    }

    let root;

    channel.on("joined", (data) => {
      // console.log("Reset stats: ", data)
      store.reset(data.data)

      requestAnimationFrame(() => {
        hydrateRoot(domContainer, <Usage />);
      });
    });

    channel.on("stats", (data) => {
      // console.log("Stats: ", data)
      store.unshift(data)
    });

  }
});

```

### `render_to_readable_stream`

```html
<div
  id="react-live-form"
  class="w-full h-full"
  phx-update="ignore"
  phx-hook="LiveFormHook"
><.react_live_form
  data={@form_data}
/></div>
```

* Work with `LiveView`

```js

const hooks = {
  LiveFormHook: {
    mounted() {
      const formState = new FormState();

      formState.setData = (data) => {
        this.pushEvent("form:input", data);
      };

      function LiveViewForm(props) {
        const data = useSyncExternalStore(formState.subscribe, formState.getSnapshot, formState.getServerSnapshot);
        return <LiveForm data={data} setData={formState.setData} />;
      }

      this.pushEvent("form:init", {}, (data, ref) => {
        formState.reset(data);
        this.reactRoot = hydrateRoot(this.el, <LiveViewForm />);
      });
      this.handleEvent("form:update", (data) => {
        formState.assign(data);
      });
    },
  }
}
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

## Hydrate at client side with CDN

Hydrate react component at client side when CDN.

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

