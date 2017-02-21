defmodule Rotterdam.PageController do
  use Rotterdam.Web, :controller

  def index(conn, _params) do
    flags = %{activeCluster: Rotterdam.ClusterManager.active_cluster()}
    IO.inspect flags
    render conn, "index.html", flags: flags
  end

end
