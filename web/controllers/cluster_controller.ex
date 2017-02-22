defmodule Rotterdam.ClusterController do
  use Rotterdam.Web, :controller

  alias Rotterdam.ClusterManager

  def index(conn, _params) do
    cluster = ClusterManager.cluster()
    render conn, "index.json", cluster: cluster
  end

  def connect(conn, _params) do
    cluster = ClusterManager.connect()
    render conn, "index.json", cluster: cluster
  end

end
