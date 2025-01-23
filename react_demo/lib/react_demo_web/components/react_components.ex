defmodule ReactDemoWeb.ReactComponents do
  @moduledoc """
  Provides React UI components.

  """
  use Phoenix.React.Component
  use Gettext, backend: ReactDemoWeb.Gettext

  def markdown(assigns) do
    props = assigns.props

    ~RF"components/markdown.js"
  end
end
