defmodule ReactDemoWeb.Router do
  use ReactDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ReactDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", ReactDemoWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/stats", PageController, :stats
  end

end
