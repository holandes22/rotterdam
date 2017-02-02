defmodule Rotterdam.ClusterController do
  use Rotterdam.Web, :controller

  alias Rotterdam.{Endpoint, ClusterManager}

  def index(conn, _params) do
    clusters = ["c1", "c2"]

    render conn, "index.html", clusters: clusters
  end

  def show(conn, %{"id" => id}) do
    Endpoint.broadcast! "state:activity", "loading", %{}
    ClusterManager.connect(id)
    render conn, "show.html", id: id
  end

end
