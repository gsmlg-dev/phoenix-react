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

  def react_markdown(assigns) do
    {static, props} = Map.pop(assigns, :static, true)

    react_component(%{
      component: "markdown",
      props: props,
      static: static
    })
  end

  @doc """
  Renders a xychart by react-dom/server.

  ## Examples

      <.react_system_stats
        data={@data}
      />

  """

  attr :data, :list, required: false, doc: "data"

  def react_system_stats(assigns) do
    {static, props} = Map.pop(assigns, :static, false)

    react_component(%{
      component: "system_usage",
      props: props,
      static: static
    })
  end


  def react_live_form(assigns) do
    {static, props} = Map.pop(assigns, :static, nil)

    react_component(%{
      component: "live_form",
      props: props,
      static: static
    })
  end
end
