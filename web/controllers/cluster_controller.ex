defmodule Rotterdam.ClusterController do
  use Rotterdam.Web, :controller

  alias Rotterdam.ClusterManager

  def index(conn, _params) do
    clusters = ClusterManager.clusters()
    render conn, "index.json", clusters: clusters
  end

  def activate(conn, %{"id" => id}) do
    cluster_status = ClusterManager.connect(id)
    render conn, "status.json", cluster_status: cluster_status
  end

end
