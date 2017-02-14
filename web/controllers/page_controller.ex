defmodule Rotterdam.PageController do
  use Rotterdam.Web, :controller

  def index(conn, _params) do
    active_cluster = Rotterdam.ClusterManager.active_cluster()
    flags = %{activeCluster: active_cluster}

    render conn, "index.html", flags: flags
  end
end
