# ReactDemo

A Phoenix application demonstrating React server-side rendering with support for both Bun and Deno runtimes.

## Getting Started

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4666`](http://localhost:4666) from your browser.

## React Runtime Options

This demo supports both Bun and Deno runtimes for React server-side rendering.

### Using Bun (Default)

```bash
mix phx.server
# or
REACT_RUNTIME=bun mix phx.server
```

### Using Deno

```bash
REACT_RUNTIME=deno mix phx.server
```

### Building for Production

#### Bun Production Build

```bash
# Build React components
mix phx.react.bun.bundle --component-base=assets/component --output=priv/react/bun/server.js

# Start production server
MIX_ENV=prod mix phx.server
# or
REACT_RUNTIME=bun MIX_ENV=prod mix phx.server
```

#### Deno Production Build

```bash
# Build React components
mix phx.react.deno.bundle --component-base=assets/component --output=priv/react/deno/server.js

# Start production server
REACT_RUNTIME=deno MIX_ENV=prod mix phx.server
```

## Configuration

The React runtime can be configured via the `REACT_RUNTIME` environment variable:

- `REACT_RUNTIME=bun` (default) - Uses Bun runtime
- `REACT_RUNTIME=deno` - Uses Deno runtime

Runtime-specific configurations are in the config files:

- **Development**: `config/dev.exs`
- **Production**: `config/prod.exs` 
- **Runtime**: `config/runtime.exs`

## Features

- [x] Server-side React rendering
- [x] Multiple runtime support (Bun & Deno)
- [x] Hot reload in development
- [x] LiveView integration
- [x] Component caching
- [x] Production bundling

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
  * Phoenix.React: https://hexdocs.pm/phoenix_react_server/
