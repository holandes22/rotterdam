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
    get "/nodes", NodeController, :index
    get "/services", ServiceController, :index
    get "/containers", ContainerController, :index
    get "/clusters/:id/activate", ClusterController, :activate
    get "/clusters/active/status", ClusterController, :status
    get "/clusters", ClusterController, :index
  end


  scope "/api", Rotterdam do
    pipe_through :api

    get "/managed-clusters", ManagedClusterController, :index
    post "/managed-clusters/:id/activate", ManagedClusterController, :activate
    get "/services/:id", ServiceController, :show

  end

end
