defmodule Phoenix.React.Runtime do
  @moduledoc """
  Phoenix.React.Runtime behaviour

  """

  defstruct [:component_base, :port, render_timeout: 300_000]

  @type t :: %__MODULE__{
          render_timeout: integer(),
          component_base: path(),
          port: port()
        }

  @type path :: binary()

  @type component :: binary()

  @type html :: binary()

  @callback start([{:component_base, path()}, {:render_timeout, integer()}]) :: port()

  @callback config() :: list()

  @callback handle_call({:render_to_string, component(), map()}, GenServer.from(), t()) ::
              {:reply, {:ok, html()}, t()} | {:reply, {:error, term()}, t()}

  @callback handle_call({:render_to_static_markup, component(), map()}, GenServer.from(), t()) ::
              {:reply, {:ok, html()}, t()} | {:reply, {:error, term()}, t()}

  defmacro __using__(_) do
    quote do
      @behaviour Phoenix.React.Runtime
      alias Phoenix.React.Runtime

      use GenServer
    end
  end
end
