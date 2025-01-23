defmodule Phoenix.React do
  @type file :: binary()
  @type props :: map()

  @doc """
  Render a React component to a string by call `renderToString` in `react-dom/server`
  """
  @spec render_to_string(file, props) :: {:ok, binary()} | {:error, term()}
  def render_to_string(file, props) do
    props = if(is_nil(props), do: %{}, else: props)
    config = Application.get_env(:phoenix_react, Phoenix.React)
    runtime = config[:runtime]
    file = if String.starts_with?(file, "/") do
      file
    else
      Path.expand(file, config[:components_base] || File.cwd!)
    end
    Phoenix.React.Server.render_to_string(runtime, file, props)
  rescue
    error ->
      {:error, error}
  end

  @doc """
  Render a React component to a string by call `renderToStaticMarkup` in `react-dom/server`
  """
  @spec render_to_static_markup(file, props) :: {:ok, binary()} | {:error, term()}
  def render_to_static_markup(file, props) do
    props = if(is_nil(props), do: %{}, else: props)
    config = Application.get_env(:phoenix_react, Phoenix.React)
    runtime = config[:runtime]
    file = if String.starts_with?(file, "/") do
      file
    else
      Path.expand(file, config[:components_base] || File.cwd!)
    end
    Phoenix.React.Server.render_to_static_markup(runtime, file, props)
  rescue
    error ->
      {:error, error}
  end
end
