defmodule Rotterdam.ServiceController do
  use Rotterdam.Web, :controller

  alias Rotterdam.ClusterManager

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => id}) do
    {:ok, service} = ClusterManager.services(id)
    render(conn, "show.json", service: service)
  end

  def create(conn, %{"name" => name, "image" => image}) do
    # TODO: deal with errors
    {:ok, id} = ClusterManager.create_service(name, image)

    conn
    |> put_status(:created)
    |> render("created.json", id: id)

  end

end
