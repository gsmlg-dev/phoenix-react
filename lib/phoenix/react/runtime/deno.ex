defmodule Phoenix.React.Runtime.Deno do
  @moduledoc """
  Phoenix.React.Runtime.Deno

  Config in `runtime.exs`

  ```
  import Config

  config :phoenix_react_server, Phoenix.React.Runtime.Deno,
    cd: File.cwd!(),
    cmd: "/path/to/deno",
    # In dev mode, the server_js will be watched and recompiled when changed
    # In prod mode, this need to be precompiled with `mix phx.react.deno.bundle`
    server_js: Path.expand("deno/server.js", :code.priv_dir(:phoenix_react_server)),
    port: 5226,
    env: :dev,
    # Security: restrict write access to specific directories
    write_dirs: ["/tmp", "/var/tmp"]
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
  def handle_continue(:start_port, %Runtime{component_base: component_base} = state) do
    if config()[:env] == :dev do
      start_file_watcher(component_base)
      Phoenix.React.Runtime.FileWatcher.set_ref(self())
    end

    port = start(component_base: component_base)

    Logger.debug(
      "Deno.Server started on port: #{inspect(port)} and OS pid: #{get_port_os_pid(port)}"
    )

    Phoenix.React.Monitoring.record_runtime_startup("Deno", config()[:port])

    Phoenix.React.Server.set_runtime_process(self())

    {:noreply, %Runtime{state | runtime_port: port}}
  end

  @impl true
  def config() do
    user_config = Application.get_env(:phoenix_react_server, Phoenix.React.Runtime.Deno, [])

    # Convert user config to map for new config system
    user_config_map =
      user_config
      |> Enum.into(%{})
      |> Map.put(:cd, Keyword.get(user_config, :cd, File.cwd!()))
      |> Map.put(:cmd, Keyword.get(user_config, :cmd, System.find_executable("deno")))
      |> Map.put(
        :server_js,
        Keyword.get(
          user_config,
          :server_js,
          Path.expand("deno/server.js", :code.priv_dir(:phoenix_react_server))
        )
      )

    case Phoenix.React.Config.runtime_config(:deno, user_config_map) do
      {:ok, config} -> Phoenix.React.Config.to_keyword_list(config)
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @impl true
  def start(component_base: _component_base) do
    config = config()
    cmd = config[:cmd]
    server_js = config[:server_js]
    deno_port = Integer.to_string(config[:port])

    is_dev = config[:env] == :dev
    deno_env = if(is_dev, do: "development", else: "production")

    # In development, use the source file with deno run
    # In production, use the compiled binary directly
    {exec_cmd, args} =
      if is_dev do
        # Use source file in development
        source_js = Path.join(Path.dirname(server_js), "server_source.js")

        # Security: restrict write access to specific directories
        write_dirs = config[:write_dirs] || ["/tmp", "/var/tmp"]
        write_args = Enum.flat_map(write_dirs, &["--allow-write=#{&1}"])

        args =
          [
            "run",
            "--allow-net",
            "--allow-read",
            "--allow-env"
          ] ++
            write_args ++
            [
              "--watch",
              "--node-modules-dir"
            ]

        {cmd, args ++ [source_js]}
      else
        # In production, server_js is the compiled binary
        {server_js, []}
      end

    env =
      runtime_env("DENO_PORT", deno_port, "DENO_ENV", deno_env) ++
        [{~c"PARENT_CHECK_INTERVAL", ~c"#{config[:parent_check_interval] || 5000}"}]

    Port.open(
      {:spawn_executable, exec_cmd},
      port_options(exec_cmd, args, cd: config[:cd], env: env)
    )
  end

  @impl true
  def start_file_watcher(component_base) do
    Logger.debug("Building server.js bundle")

    config = config()
    source_js = Path.join(Path.dirname(config[:server_js]), "server_source.js")

    bundle_args = [
      "--component-base",
      component_base,
      "--output",
      source_js,
      "--cd",
      config[:cd]
    ]

    Mix.Tasks.Phx.React.Deno.Bundle.run(bundle_args)

    Logger.debug("Starting file watcher")
    Runtime.start_file_watcher(ref: self(), path: component_base)
  end

  @impl true
  def handle_info({:component_base_changed, path}, state) do
    source_js = Path.join(Path.dirname(state.server_js), "server_source.js")

    bundle_args = [
      "--component-base",
      state.component_base,
      "--output",
      source_js,
      "--cd",
      state.cd
    ]

    handle_file_change(path, Mix.Tasks.Phx.React.Deno.Bundle, bundle_args)
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
    Logger.warning("Deno#{inspect(port)}: exit_status: #{exit_status}")
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _from, reason}, state) do
    Logger.debug("Deno.Server exiting")
    cleanup_runtime_process(state.runtime_port, reason)
    {:stop, reason, state}
  end

  @impl true
  def get_rendered_component(method, component, props, state)
      when method in [:render_to_readable_stream, :render_to_string, :render_to_static_markup] do
    server_port = config()[:port]
    timeout = state.render_timeout

    Phoenix.React.Monitoring.measure(
      "render_#{method}_#{component}",
      [:phoenix, :react, :render],
      fn ->
        result = make_http_request(server_port, Atom.to_string(method), component, props, timeout)

        # Record the result for monitoring
        case result do
          {:ok, _} -> Phoenix.React.Monitoring.record_render(component, method, 0, :ok)
          {:error, _} -> Phoenix.React.Monitoring.record_render(component, method, 0, :error)
        end

        result
      end
    )
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Deno.Server terminating")
    Phoenix.React.Monitoring.record_runtime_shutdown("Deno", reason)
    cleanup_runtime_process(state.runtime_port, reason)
  end
end
