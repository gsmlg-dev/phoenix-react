defmodule Phoenix.React.Server do
  @moduledoc false
  require Logger

  alias Phoenix.React.Cache

  use GenServer

  def config() do
    config = Application.get_env(:phoenix_react_server, Phoenix.React)
    [
      runtime: config[:runtime],
      component_base: config[:component_base],
      cache_ttl: config[:cache_ttl] || 600,
      render_timeout: config[:render_timeout] || 300_000
    ]
  end

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init([]) do
    cfg = config()

    runtime = cfg[:runtime]
    component_base = cfg[:component_base]
    render_timeout = cfg[:render_timeout]

    {:ok, runtiem_process} = GenServer.start_link(runtime, [component_base: component_base, render_timeout: render_timeout])

    {:ok, %{runtiem_process: runtiem_process}}
  end

  @impl true
  def handle_call({:render_to_string, component, props}, _from, %{runtiem_process: runtiem_process} = state) do
    reply = case Cache.get(component, props) do
      nil ->
        render_timeout = config()[:render_timeout]
        case GenServer.call(runtiem_process, {:render_to_string, component, props}, render_timeout) do
          {:ok, html} = reply ->
            Cache.put(component, props, html)
            reply
          reply -> reply
        end
      html ->
        {:ok, html}
    end
    {:reply, reply, state}
  end

  def handle_call({:render_to_static_markup, component, props}, _from, %{runtiem_process: runtiem_process} = state) do
    reply = case Cache.get(component, props) do
      nil ->
        render_timeout = config()[:render_timeout]
        case GenServer.call(runtiem_process, {:render_to_static_markup, component, props}, render_timeout) do
          {:ok, html} = reply ->
            Cache.put(component, props, html)
            reply
          reply -> reply
        end
      html ->
        {:ok, html}
    end
    {:reply, reply, state}
  end

end
