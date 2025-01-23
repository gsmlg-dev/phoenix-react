defmodule ReactDemoWeb.PageController do
  use ReactDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home, name: "Josh")
  end
end
