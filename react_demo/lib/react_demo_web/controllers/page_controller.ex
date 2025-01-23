defmodule ReactDemoWeb.PageController do
  use ReactDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
