defmodule Phoenix.React.Runtime.Bun do
  @moduledoc """
  Phoenix.React.Runtime.Bun

  Config in `runtime.exs`

  ```
  import Config

  config :phoenix_react_server, Phoenix.React.Runtime.Bun,
    cd: File.cwd!(),
    cmd: "/path/to/bun",
    # In dev mode, the server_js will be watched and recompiled when changed
    # In prod mode, this need to be precompiled with `mix phx.react.bun.bundle`
    server_js: Path.expand("bun/server.js", :code.priv_dir(:phoenix_react_server)),
    port: 5225,
    env: :dev
  ```
  """
  require Logger

  use Phoenix.React.Runtime
  import Phoenix.React.Runtime.Common

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(component_base: component_base, render_timeout: render_timeout) do
    {:ok,
     %Runtime{
       component_base: component_base,
       render_timeout: render_timeout,
       server_js: config()[:server_js],
       cd: config()[:cd]
     }, {:continue, :start_port}}
  end

  @impl true
  @spec handle_continue(:start_port, Phoenix.React.Runtime.t()) ::
          {:noreply, Phoenix.React.Runtime.t()}
          | {:stop, reason :: term, Phoenix.React.Runtime.t()}
  def handle_continue(:start_port, %Runtime{component_base: component_base} = state) do
    if config()[:env] == :dev do
      start_file_watcher(component_base)
      Phoenix.React.Runtime.FileWatcher.set_ref(self())
    end

    case start(component_base: component_base) do
      port when is_port(port) ->
        Logger.debug(
          "Bun.Server started on port: #{inspect(port)} and OS pid: #{get_port_os_pid(port)}"
        )

        Phoenix.React.Server.set_runtime_process(self())

        {:noreply, %Runtime{state | runtime_port: port}}

      {:error, reason} ->
        Logger.error("Failed to start Bun server: #{inspect(reason)}")
        {:stop, reason, state}
    end
  end

  @impl true
  def config() do
    user_config = Application.get_env(:phoenix_react_server, Phoenix.React.Runtime.Bun, [])

    # Convert user config to map for new config system
    user_config_map =
      user_config
      |> Enum.into(%{})
      |> Map.put(:cd, Keyword.get(user_config, :cd, File.cwd!()))
      |> Map.put(:cmd, Keyword.get(user_config, :cmd, System.find_executable("bun")))
      |> Map.put(
        :server_js,
        Keyword.get(
          user_config,
          :server_js,
          Path.expand("bun/server.js", :code.priv_dir(:phoenix_react_server))
        )
      )

    case Phoenix.React.Config.runtime_config(:bun, user_config_map) do
      {:ok, config} -> Phoenix.React.Config.to_keyword_list(config)
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @impl true
  def start(component_base: _component_base) do
    config = config()
    cmd = config[:cmd]
    bun_port = Integer.to_string(config[:port])
    server_js = config[:server_js]

    args = ["--port", bun_port, server_js]

    args =
      if config[:env] == :dev do
        ["--watch" | args]
      else
        args
      end

    bun_env = if(config[:env] == :dev, do: "development", else: "production")
    env = runtime_env("BUN_PORT", bun_port, "BUN_ENV", bun_env)

    Port.open({:spawn_executable, cmd}, port_options(cmd, args, cd: config[:cd], env: env))
  end

  @impl true
  def start_file_watcher(component_base) do
    Logger.debug("Building server.js bundle")

    config = config()

    bundle_args = [
      "--component-base",
      component_base,
      "--output",
      config[:server_js],
      "--cd",
      config[:cd]
    ]

    Mix.Tasks.Phx.React.Bun.Bundle.run(bundle_args)

    Logger.debug("Starting file watcher")
    Runtime.start_file_watcher(ref: self(), path: component_base)
  end

  @impl true
  def handle_info({:component_base_changed, path}, state) do
    bundle_args = [
      "--component-base",
      state.component_base,
      "--output",
      state.server_js,
      "--cd",
      state.cd
    ]

    handle_file_change(path, Mix.Tasks.Phx.React.Bun.Bundle, bundle_args)
    {:noreply, state}
  end

  @impl true
  def handle_info({_ref, :ok}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({_port, {:data, msg}}, state) do
    Logger.debug(msg)
    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:exit_status, exit_status}}, state) do
    Logger.warning("Bun#{inspect(port)}: exit_status: #{exit_status}")
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _from, reason}, state) do
    Logger.debug("Bun.Server exiting")
    cleanup_runtime_process(state.runtime_port, reason)
    {:stop, reason, state}
  end

  @impl true
  def handle_cast(:shutdown, state) do
    {:stop, :normal, state}
  end

  @impl true
  def get_rendered_component(method, component, props, state)
      when method in [:render_to_readable_stream, :render_to_string, :render_to_static_markup] do
    server_port = config()[:port]
    timeout = state.render_timeout

    make_http_request(server_port, Atom.to_string(method), component, props, timeout)
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Bun.Server terminating")
    cleanup_runtime_process(state.runtime_port, reason)
  end
end
