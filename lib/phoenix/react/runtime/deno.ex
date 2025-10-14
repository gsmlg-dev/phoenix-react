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
    env: :dev
  ```
  """
  require Logger

  use Phoenix.React.Runtime

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

    Phoenix.React.Server.set_runtime_process(self())

    {:noreply, %Runtime{state | runtime_port: port}}
  end

  @impl true
  def config() do
    cfg = Application.get_env(:phoenix_react_server, Phoenix.React.Runtime.Deno, [])
    cmd = cfg[:cmd] || System.find_executable("deno")

    server_js =
      cfg[:server_js] || Path.expand("deno/server.js", :code.priv_dir(:phoenix_react_server))

    [
      {:cd, cfg[:cd] || File.cwd!()},
      {:cmd, cmd},
      {:server_js, server_js},
      {:port, cfg[:port] || 5226},
      {:env, cfg[:env] || :dev}
    ]
  end

  @impl true
  def start(component_base: component_base) do
    cd = config()[:cd]
    cmd = config()[:cmd]
    server_js = config()[:server_js]
    deno_port = Integer.to_string(config()[:port])

    is_dev = config()[:env] == :dev
    deno_env = if(is_dev, do: "development", else: "production")

    # In development, use the source file with deno run
    # In production, use the compiled binary directly
    {exec_cmd, args} =
      if is_dev do
        # Use source file in development
        source_js = Path.join(Path.dirname(server_js), "server_source.js")

        args = [
          "run",
          "--allow-net",
          "--allow-read",
          "--allow-env",
          "--allow-write",
          "--watch",
          "--node-modules-dir"
        ]

        {cmd, args ++ [source_js]}
      else
        # In production, server_js is the compiled binary
        {server_js, []}
      end

    env = [
      {~c"PORT", ~c"#{deno_port}"},
      {~c"DENO_PORT", ~c"#{deno_port}"},
      {~c"DENO_ENV", ~c"#{deno_env}"},
      {~c"COMPONENT_BASE", ~c"#{component_base}"}
    ]

    Port.open(
      {:spawn_executable, exec_cmd},
      [
        {:args, args},
        {:cd, cd},
        {:env, env},
        :stream,
        :binary,
        :exit_status,
        :use_stdio,
        :stderr_to_stdout
      ]
    )
  end

  @impl true
  def start_file_watcher(component_base) do
    Logger.debug("Building server.js bundle")

    # In development, create source file for deno run
    source_js = Path.join(Path.dirname(config()[:server_js]), "server_source.js")

    Mix.Tasks.Phx.React.Deno.Bundle.run([
      "--component-base",
      component_base,
      "--output",
      source_js,
      "--cd",
      config()[:cd]
    ])

    Logger.debug("Starting file watcher")
    Runtime.start_file_watcher(ref: self(), path: component_base)
  end

  @impl true
  def handle_info({:component_base_changed, path}, state) do
    Task.async(fn ->
      Logger.debug("component_base changed: #{path}, rebuilding...")

      # In development, rebuild source file
      source_js = Path.join(Path.dirname(state.server_js), "server_source.js")

      Mix.Tasks.Phx.React.Deno.Bundle.run([
        "--component-base",
        state.component_base,
        "--output",
        source_js,
        "--cd",
        state.cd
      ])

      Logger.debug("component_base rebuilt #{path}")
    end)
    |> Task.await()

    {:noreply, state}
  end

  def handle_info({_ref, :ok}, state) do
    {:noreply, state}
  end

  def handle_info({_port, {:data, msg}}, state) do
    Logger.debug(msg)
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, exit_status}}, state) do
    Logger.warning("Deno#{inspect(port)}: exit_status: #{exit_status}")
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  # handle the trapped exit call
  def handle_info({:EXIT, _from, reason}, state) do
    Logger.debug("Deno.Server exiting")
    cleanup(reason, state)
    {:stop, reason, state}
  end

  @impl true
  def get_rendered_component(method, component, props, state)
      when method in [:render_to_readable_stream, :render_to_string, :render_to_static_markup] do
    server_port = config()[:port]

    url = ~c"http://localhost:#{server_port}/#{method}/#{component}"
    headers = [{~c"Content-Type", ~c"application/json"}]
    body = Jason.encode!(props)

    timeout = state.render_timeout

    case :httpc.request(
           :post,
           {~c"#{url}", headers, ~c"application/json", body},
           [timeout: timeout, connect_timeout: timeout],
           body_format: :binary
         ) do
      {:ok, {{_version, status_code, _status_text}, _headers, body}}
      when status_code in 200..299 ->
        {:ok, to_string(body)}

      {:ok, {{_version, status_code, _status_text}, _headers, body}} ->
        {:error, "HTTP #{status_code}\n\n#{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Deno.Server terminating")
    cleanup(reason, state)
  end

  defp cleanup(reason, %Runtime{runtime_port: runtime_port} = _state) do
    case runtime_port |> Port.info(:os_pid) do
      {:os_pid, pid} ->
        {_, code} = System.cmd("kill", ["-9", "#{pid}"])
        code

      _ ->
        0
    end

    case reason do
      :normal -> :normal
      :shutdown -> :shutdown
      term -> {:shutdown, term}
    end
  end

  defp get_port_os_pid(runtime_port) do
    case runtime_port |> Port.info(:os_pid) do
      {:os_pid, pid} -> pid
      _ -> nil
    end
  end
end
