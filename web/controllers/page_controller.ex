defmodule Rotterdam.PageController do
  use Rotterdam.Web, :controller

  def index(conn, _params) do
    flags = %{cluster: Rotterdam.ClusterManager.cluster()}
    render conn, "index.html", flags: flags
  end

end
