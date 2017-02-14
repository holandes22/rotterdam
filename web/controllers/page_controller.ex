defmodule Rotterdam.PageController do
  use Rotterdam.Web, :controller

  def index(conn, _params) do
    props = %{
      clusters: [
        %{id: 1, label: "ClusterA"},
        %{id: 2, label: "Cluster2"},
      ]
    }

    render conn, "index.html", props: props
  end
end
