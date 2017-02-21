# TODO: move to separate file and rename module to Rotterdam.Managed.*
defmodule Cluster do
  defstruct id: nil,
            label: nil,
            nodes: [],
            active: false
end


# TODO: conn field does not belong here as it is
# an internal detail of the manager. Refactor
# start_nodes to handle this and hold the conns
# in state instead
defmodule ManagedNode do
  defstruct id: nil,
            label: nil,
            role: nil,
            host: nil,
            port: "2376",
            cert_path: nil,
            status: :stopped,
            status_msg: "",
            conn: nil
end


defmodule Rotterdam.ClusterManager do
  use GenServer

  require Logger

  import Supervisor.Spec, only: [worker: 3]

  alias Rotterdam.{Service, Node}
  alias Rotterdam.Event.Docker.PipelineSupervisor
  alias Rotterdam.Event.Docker.{Producer, EventsBroadcast, StateBroadcast}


  # Public API
  # ----------

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_params) do
    clusters = get_configured_clusters()
    {:ok, %{active_cluster: nil, clusters: clusters}}
  end

  def active_cluster, do: GenServer.call(__MODULE__, :active_cluster)

  def clusters, do: GenServer.call(__MODULE__, :clusters)

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def services, do: GenServer.call(__MODULE__, :services)
  def services(id), do: GenServer.call(__MODULE__, {:services, id})

  def containers_per_node, do: GenServer.call(__MODULE__, :containers_per_node)

  def connect(cluster), do: GenServer.call(__MODULE__, {:connect, cluster})

  # GenServer callbacks
  # -------------------

  def handle_call({:connect, cluster_id}, _from, %{clusters: clusters}) do
    # TODO: return error if no such cluster id
    state =
      cluster_id
      |> get_cluster_by_id(clusters)
      |> activate_cluster()
      |> get_active_state(clusters)

    clusters =
      state.clusters
      |> remove_conns()

    {:reply, clusters, state}
  end

  def handle_call(:active_cluster, _from, %{active_cluster: nil} = state) do
    {:reply, nil, state}
  end
  def handle_call(:active_cluster, _from, %{active_cluster: cluster} = state) do
    cluster = remove_conns(cluster)
    {:reply, cluster, state}
  end

  def handle_call(:clusters, _from, %{clusters: clusters} = state) do
    clusters = remove_conns(clusters)
    {:reply, clusters, state}
  end

  # All handle_call below this point require an active cluster

  def handle_call(_, _from, %{active_cluster: nil} = state) do
    {:reply, {:error, :no_active_cluster}, state}
  end

  def handle_call(:nodes, _from, state) do
    conn = get_conn(state)
    reply =
      conn
      |> Dox.nodes()
      |> ok()
      |> Node.normalize()

    {:reply, {:ok, reply}, state}
  end

  def handle_call(:services, _from, state) do
    conn = get_conn(state)
    reply =
      conn
      |> Dox.services()
      |> ok()
      |> Service.normalize()

    {:reply, {:ok, reply}, state}
  end

  def handle_call({:services, id}, _from, state) do
    conn = get_conn(state)
    reply =
      conn
      |> Dox.services(id)
      |> ok()
      |> Service.normalize()

    {:reply, {:ok, reply}, state}
  end

  def handle_call(:containers_per_node, _from, state) do
    {:reply, {:ok, containers_per_node(state)}, state}
  end

  defp ok({:ok, value}), do: value

  defp containers_per_node(state)do
    nodes = get_connected_nodes(state)

    for %{conn: conn, id: id, label: label} <- nodes, into: [] do
      containers =
        conn
        |> Dox.containers()
        |> ok()

      %{id: id, label: label, containers: containers}
    end
  end

  defp get_connected_nodes(state) do
    Enum.filter(state.active_cluster.nodes, fn(node) ->
      match?(%{conn: %{status: _}}, node)
    end)
  end

  defp get_conn(state) do
    node = get_node_by_role(:manager, state.active_cluster.nodes)
    node.conn
  end

  defp get_node_by_role(role, nodes) do
    Enum.find(nodes, fn(node) ->
      match?(%{role: role, conn: %{status: _}}, node)
    end)
  end

  defp get_cluster_by_id(id, clusters) do
    # TODO: return error if no such ID
    Enum.find(clusters, fn(cluster) ->
      match?(%Cluster{id: ^id}, cluster)
    end)
  end

  defp get_configured_clusters() do
    [
      %Cluster{
        id: "cluster1",
        label: "Alpha",
        nodes: [
          %ManagedNode{
            id: :node1,
            label: "Manager",
            role: :manager,
            host: "192.168.99.100",
            cert_path: "/home/pablo/.docker/machine/machines/cluster1-node1"
          },
          %ManagedNode{
            id: :node2,
            label: "Worker1",
            role: :worker,
            host: "192.168.99.101",
            cert_path: "/home/pablo/.docker/machine/machines/cluster1-node2"
          },
        ]
      },
    ]
  end

  defp get_active_state(active_cluster, clusters) do
    index = Enum.find_index(clusters, fn(c) -> c.id == active_cluster.id end)
    clusters = [active_cluster] ++ List.delete_at(clusters, index)
    %{active_cluster: active_cluster, clusters: clusters}
  end

  defp activate_cluster(cluster) do
    nodes = start_nodes(cluster)
    %Cluster{cluster | active: true, nodes: nodes}
  end

  defp start_nodes(cluster) do
    for node <- cluster.nodes do
      case start_node(node) do
        {:ok, status, conn} ->
          %ManagedNode{node | conn: conn, status: status}
        {:error, msg} ->
          %ManagedNode{node | status: :failed, status_msg: msg}
      end
    end
  end

  defp start_node(%{host: host, port: port, cert_path: cert_path, id: id}) do
    case Dox.conn(host, port, cert_path) do
      {:ok, conn} ->
        create_event_pipeline(conn, id)
        Logger.info "Docker producer from host #{host} started"
        {:ok, :started, conn}
      {:error, msg} ->
        Logger.error "Failed to start #{host}. #{msg}"
        {:error, msg}
    end
  end

  defp create_event_pipeline(conn, label) do
    id = "producer_" <> Atom.to_string(label)
    child = worker(Producer, [conn, label], id: id)

    case Supervisor.start_child(PipelineSupervisor, child) do
      {:ok, pid} ->
        start_stages(pid)
      {:error, {:already_started, pid}} ->
        start_stages(pid)
    end
  end

  defp start_stages(producer) do
    events_pid = Process.whereis(EventsBroadcast)
    state_pid = Process.whereis(StateBroadcast)

    GenStage.sync_subscribe(events_pid, to: producer)
    GenStage.sync_subscribe(state_pid, to: producer)
  end

  defp remove_conns(%Cluster{} = cluster) do
    nodes = for node <- cluster.nodes do
      Map.delete(node, :conn)
    end

    %{cluster | nodes: nodes}
  end
  defp remove_conns(clusters) when is_list(clusters) do
    for cluster <- clusters do
      remove_conns(cluster)
    end
  end

end
