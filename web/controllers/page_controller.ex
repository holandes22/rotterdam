defmodule Rotterdam.PageController do
  use Rotterdam.Web, :controller

  def index(conn, _params) do
    flags = %{clusterStatus: cluster_status()}
    render conn, "index.html", flags: flags
  end

  defp cluster_status do
    case Rotterdam.ClusterManager.cluster_status() do
      {:active, status} ->
        status
      {:inactive, nil} ->
        nil
    end

  end
end
