defmodule ReactDemoWeb.PageController do
  use ReactDemoWeb, :controller

  def home(conn, _params) do
    markdown_doc = """
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
    {:phoenix_react_server, "~> #{Application.spec(:phoenix_react_server, :vsn)}"},
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
    - [ ] `Phoenix.React.Runtime.Node`
    - [ ] `Phoenix.React.Runtime.Lambda`

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

    ## Use in otp release

    Transcompile react component in release.

    ```shell
    bun build --outdir=priv/react/component ./assets/component/**
    ```

    Config `runtime` to `Phoenix.React.Runtime.Bun` in `runtime.exs`

    ```elixir
    config :phoenix_react_server, Phoenix.React,
      # Change `component_base` to `priv/react/component`
      component_base: :code.priv(:react_demo, "react/component")

    config :phoenix_react_server, Phoenix.React.Runtime.Bun,
      # include `react-dom/server` and `jsx-runtime`
      cd: "/path/to/dir/include/node_modules/and/bunfig.toml",
      cmd: "/path/to/bun",
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

    """
    render(conn, :home, markdown_doc: markdown_doc)
  end

  def stats(conn, _params) do
    stats = SystemStats.get_stats()

    data = stats |> Enum.map(fn({time, cpu, mem}) ->
      %{ date: time, cpu: cpu, mem: mem }
    end)

    render(conn, :stats, data: data)
  end
end
