defmodule Rotterdam.ServiceController do
  use Rotterdam.Web, :controller

  alias Rotterdam.ClusterManager

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => id}) do
    service = ClusterManager.services(id)
    render(conn, "show.json", service: service)
  end

end
