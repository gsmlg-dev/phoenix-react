defmodule ReactDemoWeb.ReactComponents do
  @moduledoc """
  Provides React UI components.

  """
  use Phoenix.Component
  import Phoenix.React.Helper
  use Gettext, backend: ReactDemoWeb.Gettext

  require Logger

  @doc """
  Renders a markdown by react-dom/server.

  ## Examples

      <.react_markdown
        data={@markdown_doc}
      />

  """
  attr :data, :string, required: true, doc: "markdown data"
  attr :static, :boolean, default: true, doc: "when true, render to static markup, false to render to string for client-side hydrate"

  def react_markdown(assigns) do
    {static, props} = Map.pop(assigns, :static, true)

    react_component(%{
      component: "markdown",
      props: props,
      static: static
    })
  end
end
