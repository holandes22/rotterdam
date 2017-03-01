defmodule Rotterdam.Router do
  use Rotterdam.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Rotterdam do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", Rotterdam do
    pipe_through :api

    get "/cluster", ClusterController, :index
    post "/cluster/connect", ClusterController, :connect
    get "/services/:id", ServiceController, :show
    post "/services", ServiceController, :create

  end

end
