defmodule Phoenix.React do
  @type file :: binary()
  @type props :: map()

  @doc """
  Render a React component to a string by call `renderToString` in `react-dom/server`
  """
  @spec render_to_string(file, props) :: binary()
  def render_to_string(file, props) do
    runtime = Application.get_env(:phoenix_react, Phoenix.React)[:runtime]
    Phoenix.React.Server.render_to_string(runtime, file, props)
  end

  @doc """
  Render a React component to a string by call `renderToStaticMarkup` in `react-dom/server`
  """
  @spec render_to_static_markup(file, props) :: binary()
  def render_to_static_markup(file, props) do
    runtime = Application.get_env(:phoenix_react, Phoenix.React)[:runtime]
    Phoenix.React.Server.render_to_static_markup(runtime, file, props)
  end
end
