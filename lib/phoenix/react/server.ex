defmodule Phoenix.React.Server do
  @moduledoc false
  require Logger
  use GenServer

  def render_to_string(runtime, file, props) do
    GenServer.call(__MODULE__, {:render_to_string, runtime, file, props})
  end

  def render_to_static_markup(runtime, file, props) do
    GenServer.call(__MODULE__, {:render_to_static_markup, runtime, file, props})
  end

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init([]) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:render_to_string, runtime, file, props}, _from, state) do
    reply = Phoenix.React.Cache.get(__MODULE__, :render_task, [:string, runtime, file, props])
    {:reply, reply, state}
  end

  def handle_call({:render_to_static_markup, runtime, file, props}, _from, state) do
    reply = Phoenix.React.Cache.get(__MODULE__, :render_task, [:static, runtime, file, props])
    {:reply, reply, state}
  end

  def render_task(type, runtime, file, props) do
    Task.Supervisor.async(Pohoenix.React.RenderTaskSupervisr, fn ->
      render(type, runtime, file, props)
    end) |> Task.await(300_000)
  end

  defp render(:string, runtime, file, props) do
    js = """
    import * as React from 'react';
    import { renderToString } from 'react-dom/server';
    import Component from '#{file}';
    const props = #{Jason.encode!(props)};
    const el = React.createElement(Component, props);
    const html = renderToString(el);
    process.stdout.write(html);
    """

    js_file = Path.join(:code.priv_dir(:phoenix_react), "tmp/render.js")
    File.write!(js_file, js)

    case System.cmd(runtime, [js_file]) do
      {html, 0} -> {:ok, html}
      {msg, code} -> {:error, code, msg}
    end
  end

  defp render(:static, runtime, file, props) do
    js = """
    import * as React from 'react';
    import { renderToStaticMarkup } from 'react-dom/server';
    import Component from '#{file}';
    const props = #{Jason.encode!(props)};
    const el = React.createElement(Component, props);
    const html = renderToStaticMarkup(el);
    process.stdout.write(html);
    """

    js_file = Path.join(:code.priv_dir(:phoenix_react), "tmp/render.js")
    File.write!(js_file, js)

    case System.cmd(runtime, [js_file]) do
      {html, 0} -> {:ok, html}
      {msg, code} -> {:error, code, msg}
    end
  end
end
