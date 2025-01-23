defmodule Phoenix.React.Component do
  @moduledoc false
  require Logger

  @doc type: :macro
  defmacro sigil_RF({:<<>>, meta, [expr]}, modifiers) do
    if not Macro.Env.has_var?(__CALLER__, {:props, nil}) do
      raise "~rf requires a variable named \"props\" to exist and be set to a map"
    end
    Logger.debug("~RF context: #{inspect(binding(__CALLER__.context))} and modifiers: #{inspect(modifiers)}")
    props = binding(__CALLER__.context)[:props]

    result = case modifiers do
      [] -> Phoenix.React.render_to_string(expr, props)
      ["s"] -> Phoenix.React.render_to_static_markup(expr, props)
    end

    html = case result do
      {:ok, html} ->
        Logger.debug("react to string: #{html}")
        html
      {:error, error} ->
        Logger.warning("react to string error, #{inspect(error)}")
        ""
    end

    options = [
      engine: Phoenix.LiveView.TagEngine,
      file: __CALLER__.file,
      line: __CALLER__.line + 1,
      caller: __CALLER__,
      indentation: meta[:indentation] || 0,
      source: expr,
      tag_handler: Phoenix.LiveView.HTMLEngine
    ]

    EEx.compile_string(html, options)
  end

  defmacro __using__(_) do
    quote do
      import Phoenix.React.Component
    end
  end
end
