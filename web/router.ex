defmodule Rotterdam.Router do
  use Rotterdam.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Rotterdam.Plug.ActiveCluster
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

    get "/clusters", ClusterController, :index
    post "/clusters/:id/activate", ClusterController, :activate
    get "/services/:id", ServiceController, :show

  end

end
