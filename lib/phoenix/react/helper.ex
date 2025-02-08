defmodule Phoenix.React.Helper do
  @moduledoc """
  A helper to render react component by `react-dom/server` in `Phoenix.Component`.

  Usage:

  ```elixir
  # in html_helpers in AppWeb.ex
  import Phoenix.React.Helper
  ```

  """
  require Logger

  use Phoenix.Component

  @doc """
  A helper to render react component by `react-dom/server` in `Phoenix.Template`.

  attrs:
    - `component`: react component name
    - `props`: props will pass to react component
    - `static`: when true, render to static markup, false to render to string for client-side hydrate

  ## Examples

      <.react_component
        component="awesome-chart"
        props={%{ data: @chart_data }}
        static={false}
      />

  ### `component`

  Component file is set at `Application.get_env(:phoenix_react_server, Phoenix.React)[:component_base]`
  The component file should export a `Component` function:

  ```javascript
  import Chart from 'awesome-chart';
  export const Component = ({data}) => {
    return <Chart data={data} />;
  }
  ```
  """
  attr(:component, :string,
    required: true,
    doc: """
    react component name
    ```
    """
  )

  attr(:props, :map,
    default: %{},
    doc: """
    props will pass to react component
    """
  )

  attr(:static, :boolean,
    default: true,
    doc: """
    when true, render to static markup, false to render to string for client-side hydrate
    """
  )

  def react_component(assigns) do
    component = assigns[:component]
    props = assigns[:props]
    static = assigns[:static]

    method =
      if static do
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
        Logger.error(
          "Failed to render react component #{component} with #{inspect(props)}, error: #{inspect(error)}"
        )

        error_html =
          if is_binary(error) do
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
end
