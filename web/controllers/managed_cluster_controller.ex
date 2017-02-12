defmodule Rotterdam.ManagedClusterController do
  use Rotterdam.Web, :controller

  alias Rotterdam.ClusterManager

  def index(conn, _params) do
    clusters = %{
      swarm: [
        %{label: "c1", active: true},
        %{label: "c2", active: false},
      ]
    }

    render conn, "index.json", clusters: clusters
  end

  def activate(conn, %{"id" => id}) do
    cluster_status = ClusterManager.connect(id)
    render conn, "status.json", cluster_status: cluster_status
  end

end
