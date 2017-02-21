defmodule Rotterdam.ClusterController do
  use Rotterdam.Web, :controller

  alias Rotterdam.ClusterManager

  def index(conn, _params) do
    clusters = ClusterManager.clusters()
    render conn, "index.json", clusters: clusters
  end

  def activate(conn, %{"id" => id}) do
    clusters = ClusterManager.connect(id)
    render conn, "index.json", clusters: clusters
  end

end
