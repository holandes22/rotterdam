defmodule Rotterdam.ClusterController do
  use Rotterdam.Web, :controller

  alias Rotterdam.ClusterManager

  def index(conn, _params) do
    clusters = [
        %{
          id: "c1",
          label: "c1",
          active: true,
          nodes: [
            %{
              label: "n1",
              status: :started
            },
            %{
              label: "n2",
              status: :failed
            }

          ]
        },
        %{
          id: "c2",
          label: "c2",
          active: false,
          nodes: [
            %{
              label: "n1",
              status: :stopped
            },
            %{
              label: "n2",
              status: :stopped
            }

          ]
        },
      ]

    render conn, "index.json", clusters: clusters
  end

  def activate(conn, %{"id" => id}) do
    cluster_status = ClusterManager.connect(id)
    render conn, "status.json", cluster_status: cluster_status
  end

end
