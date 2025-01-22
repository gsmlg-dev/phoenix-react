defmodule Phoenix.React do
  @type file :: binary()
  @type props :: map()

  @doc """
  Render a React component to a string by call `.
  ```
  import { renderToString } from 'react-dom/server';
  import Component from '<%= file %>';
  const props = <%= Jason.encode!(props) %>
  const html = renderToString(<App {...props} />);
  ```
  """
  @spec render_to_string(file, props) :: binary()
  def render_to_string(file, props) do
    runtime = Application.get_env(:phoenix_react, Phoenix.React)[:runtime]
    Phoenix.React.Server.render_to_string(runtime, file, props)
  end
end
