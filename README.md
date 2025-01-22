# Phoenix.React

[![release](https://github.com/gsmlg-dev/phoenix-react/actions/workflows/test-and-release.yml/badge.svg)](https://github.com/gsmlg-dev/phoenix-react/actions/workflows/test-and-release.yml)

Run a `react` render server to render react component in `Phoenix` html.

**Features**

- Render to static markup
- Render to html
- Render to html and use hydrate at client side by `live_view` `hook`

See the [docs](https://hexdocs.pm/phoenix_react/) for more information.

## Install this package

Add deps in `mix.exs`

```elixir
    {:phoenix_react, "~> 0.1.0"},
```

## Configuration

`Javascript` runtime

- `babel` with `nodejs`
- `deno`
- `bun`

