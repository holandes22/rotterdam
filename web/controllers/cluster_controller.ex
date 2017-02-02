defmodule Rotterdam.ClusterController do
  use Rotterdam.Web, :controller

  alias Rotterdam.{Endpoint, ClusterManager, Plug}

  #plug Plug.ActiveCluster


  def index(conn, _params) do
    clusters = ["c1", "c2"]

    render conn, "index.html", clusters: clusters
  end

  def activate(conn, %{"id" => id}) do
    Endpoint.broadcast! "state:activity", "loading", %{}
    ClusterManager.connect(id)
    redirect conn, to: cluster_path(conn, :status)
  end

  def status(conn, _params) do
    cluster_status = ClusterManager.cluster_status()
    render conn, "status.html", cluster_status: cluster_status
  end

end
