defmodule Rotterdam.Plug.ActiveCluster do
  import Plug.Conn

  alias Rotterdam.ClusterManager

  def init(options), do: options

  def call(conn, _opts) do
    active_cluster = ClusterManager.active_cluster()

    assign(conn, :active_cluster, active_cluster)
  end

end
