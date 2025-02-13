defmodule ReactDemoWeb.FormLive.Index do
  use ReactDemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Live Form")
    |> assign(:form_data, FormProcess.get_form_data())
  end

  @impl true
  def handle_event("form:init", %{}, socket) do
    form_data = socket.assigns.form_data
    {:reply, form_data, socket}
  end

  @impl true
  def handle_event("form:input", data, socket) do
    form_data = socket.assigns.form_data
      |> Map.merge(data)

    FormProcess.set_form_data(form_data)

    socket = socket
      |> assign(:form_data, form_data)
      |> push_event("form:update", form_data)

    {:noreply, socket}
  end
end
