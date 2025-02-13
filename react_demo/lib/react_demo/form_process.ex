
defmodule FormProcess do
  use GenServer

  @init_form_data %{
    "content" => """
    # Hello, this is Phoenix.React!
    Phoenix.React is a library that allows you to render React components in your Phoenix application.

    You can live input and preview the markdown content in this form.

    What you see is what you get!

    Form data is set in server, so no need to worry about losing data when you refresh the page.
    """
  }

  def get_form_data do
    GenServer.call(__MODULE__, :get_form_data)
  end

  def set_form_data(form_data) when is_map(form_data) do
    GenServer.cast(__MODULE__, {:set_form_data, form_data})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, @init_form_data, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_form_data, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:set_form_data, form_data}, state) do
    {:noreply, state |> Map.merge(form_data)}
  end
end
