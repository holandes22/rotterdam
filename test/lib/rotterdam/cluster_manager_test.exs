defmodule Rotterdam.ClusterManagerTest do
  use ExUnit.Case, async: true
  alias Rotterdam.{Managed, ClusterManager}

  setup do
    bypass = Bypass.open()

    {:ok, bypass: bypass}
  end

  test "getting resources with inactive cluster" do
    ClusterManager.clear_conn()
    assert ClusterManager.nodes == {:error, :cluster_inactive}
  end

  test "getting resources with no connections", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      Plug.Conn.resp(conn, 500, "")
    end

    ClusterManager.clear_conn()
    connect(bypass)

    assert ClusterManager.nodes == {:error, :no_active_conns}
  end

  test "connection", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/v1.24/version" == conn.request_path
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"Version": "1.12.0"}>)
    end

    cluster = connect(bypass)
    node = List.first(cluster.nodes)

    assert cluster.connected
    assert node.id == :node1
  end

  defp connect(bypass) do
    bypass.port
      |> Integer.to_string()
      |> cluster_config()
      |> ClusterManager.connect(start_event_pipeline: false)
  end

  defp cluster_config(port) do
    %Managed.Cluster{
      label: "Alpha",
      nodes: [
        %Managed.Node{
          id: :node1,
          label: "Manager",
          role: :manager,
          host: "localhost",
          port: port
        }
      ]
    }
  end

end
