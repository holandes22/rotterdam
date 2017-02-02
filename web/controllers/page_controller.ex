defmodule Rotterdam.PageController do
  use Rotterdam.Web, :controller

  def index(conn, _params) do
    props = %{
      clusters: [
        %{id: 1, label: "Cluster1"},
        %{id: 2, label: "Cluster2"},
      ]
    }

    render conn, "index.html", props: props
  end
end
