defmodule Rotterdam.NodeController do
  use Rotterdam.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

end