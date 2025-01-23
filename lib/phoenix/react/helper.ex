defmodule Phoenix.React.Helper do
  @moduledoc false
  require Logger

  def react_component(assigns) do
    component = assigns[:component]
    props = assigns[:props]
    static = assigns[:static]

    method = if static do
      :render_to_static_markup
    else
      :render_to_string
    end

    case apply(Phoenix.React, method, [component, props]) do
    {:ok, html} ->
      %Phoenix.LiveView.Rendered{
        static: [html],
        dynamic: fn _assigns -> [] end,
        fingerprint: :erlang.phash2("components/markdown.js"),
        root: nil,
        caller: :not_available
      }
    {:error, error} ->
      Logger.error("Failed to render react component #{component} with #{inspect(props)}, error: #{inspect(error)}")
      error_html = if is_binary(error) do
        error
      else
        "Failed to render react component: #{inspect(error)}"
      end
      %Phoenix.LiveView.Rendered{
        static: [error_html],
        dynamic: fn _assigns -> [] end,
        fingerprint: :erlang.phash2(component),
        root: nil,
        caller: :not_available
      }
    end
  end

  defmacro __using__(_) do
    quote do
      import Phoenix.React.Helper
    end
  end
end
