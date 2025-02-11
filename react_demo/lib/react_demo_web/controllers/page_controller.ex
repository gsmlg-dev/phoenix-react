defmodule ReactDemoWeb.PageController do
  use ReactDemoWeb, :controller

  def home(conn, _params) do
    file = Path.expand("../../../../README.md", __DIR__)
    markdown_doc = File.read!(file)

    render(conn, :home, markdown_doc: markdown_doc)
  end

  def stats(conn, _params) do
    stats = SystemStats.get_stats()

    data = stats |> Enum.map(fn({time, cpu, mem}) ->
      %{ date: time, cpu: cpu, mem: mem }
    end)

    render(conn, :stats, data: data)
  end
end
