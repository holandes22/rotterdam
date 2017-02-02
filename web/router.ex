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
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/nodes", NodeController, :index
    get "/services", ServiceController, :index
    get "/containers", ContainerController, :index
    resources "/clusters", ClusterController, only: [:index, :show]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Rotterdam do
  #   pipe_through :api
  # end
end
