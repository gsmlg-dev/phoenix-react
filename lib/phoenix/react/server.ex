defmodule Phoenix.React.Server do
  @moduledoc false
  require Logger
  use GenServer

  def render_to_string(runtime, file, props) do
    Logger.debug("render_to_string: #{inspect(runtime)} #{inspect(file)} #{inspect(props)}")
    if is_nil(Process.whereis(__MODULE__)) do
      render(:string, runtime, file, props)
    else
      GenServer.call(__MODULE__, {:render_to_string, runtime, file, props}, 30_000)
    end
  end

  def render_to_static_markup(runtime, file, props) do
    Logger.debug("render_to_static_markup: #{inspect(runtime)} #{inspect(file)} #{inspect(props)}")
    if is_nil(Process.whereis(__MODULE__)) do
      render(:static, runtime, file, props)
    else
      GenServer.call(__MODULE__, {:render_to_static_markup, runtime, file, props})
    end
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

    tmp_dir = Path.expand("tmp", :code.priv_dir(:phoenix_react))
    File.exists?(tmp_dir) || File.mkdir_p!(tmp_dir)
    n = Enum.random(0..999_999)
    js_file = Path.expand("compile-#{n}.js", tmp_dir)
    File.write!(js_file, js)

    case System.cmd(runtime, [js_file]) do
      {html, 0} ->
        File.rm(js_file)
        {:ok, html}
      {msg, code} ->
        # File.rm(js_file)
        {:error, code, msg}
    end

    # case System.cmd(runtime, ["--eval", js]) do
    #   {html, 0} -> {:ok, html}
    #   {msg, code} -> {:error, code, msg}
    # end
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

    tmp_dir = Path.expand("tmp", :code.priv_dir(:phoenix_react))
    File.exists?(tmp_dir) || File.mkdir_p!(tmp_dir)
    n = Enum.random(0..999_999)
    js_file = Path.expand("compile-#{n}.js", tmp_dir)
    File.write!(js_file, js)

    case System.cmd(runtime, [js_file]) do
      {html, 0} ->
        File.rm(js_file)
        {:ok, html}
      {msg, code} ->
        # File.rm(js_file)
        {:error, code, msg}
    end

    # case System.cmd(runtime, ["--eval", js]) do
    #   {html, 0} -> {:ok, html}
    #   {msg, code} -> {:error, code, msg}
    # end

  end
end
