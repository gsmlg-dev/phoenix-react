defmodule Phoenix.React.Helper do
  @moduledoc false
  require Logger

  def react_component(file, props, _opts \\ []) do
    {:ok, html} = Phoenix.React.render_to_string(file, props)

    %Phoenix.LiveView.Rendered{
      static: [html],
      dynamic: fn _assigns -> [] end,
      fingerprint: :erlang.phash2("components/markdown.js"),
      root: nil,
      caller: :not_available
    }
  end

  defmacro __using__(_) do
    quote do
      import Phoenix.React.Helper
    end
  end
end
