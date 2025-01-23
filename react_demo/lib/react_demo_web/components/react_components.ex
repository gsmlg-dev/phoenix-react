defmodule ReactDemoWeb.ReactComponents do
  @moduledoc """
  Provides React UI components.

  """
  use Phoenix.Component
  use Phoenix.React.Helper
  use Gettext, backend: ReactDemoWeb.Gettext

  require Logger

  def markdown(assigns) do
    props = assigns.props

    react_component("components/markdown.js", props)
  end
end
