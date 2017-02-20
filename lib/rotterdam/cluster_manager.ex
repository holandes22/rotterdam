defmodule Cluster do
  defstruct id: nil,
            label: nil,
            nodes: [],
            active: false
end


defmodule CNode do
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

  # TODO: return error if calling API with no active cluster

  def init(_params) do
    clusters = get_configured_clusters()
    {:ok, %{clusters: clusters}}
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

  def handle_call({:connect, cluster_id}, _from, %{clusters: clusters} = state) do
    # TODO: return error if no such cluster id
    clusters =
      cluster_id
      |> get_cluster_by_id(clusters)
      |> activate_cluster()
      |> update_active_cluster(clusters)

    {:reply, clusters, %{state | clusters: clusters}}
  end

  def handle_call(:active_cluster, _from, %{clusters: clusters} = state) do
    cluster = get_active_cluster(clusters)
    {:reply, cluster, state}
  end

  def handle_call(:clusters, _from, %{clusters: clusters} = state) do
    {:reply, clusters, state}
  end

  def handle_call(:nodes, _from, state) do
    conn = get_conn(:manager, state)
    response =
      conn
      |> Dox.nodes()
      |> ok()
      |> Node.normalize()

    {:reply, response, state}
  end

  def handle_call(:services, _from, state) do
    conn = get_conn(:manager, state)
    response =
      conn
      |> Dox.services()
      |> ok()
      |> Service.normalize()

    {:reply, response, state}
  end
  def handle_call({:services, id}, _from, state) do
    conn = get_conn(:manager, state)
    response =
      conn
      |> Dox.services(id)
      |> ok()
      |> Service.normalize()

    {:reply, response, state}
  end

  def handle_call(:containers_per_node, _from, state) do
    {:reply, containers_per_node(state), state}
  end

  defp ok({:ok, value}), do: value

  defp containers_per_node(state)do
    nodes = get_connected_nodes(state)

    for {label, %{conn: conn}} <- nodes, into: [] do
      containers =
        conn
        |> Dox.containers()
        |> ok()
      %{node: label, containers: containers}
    end
  end

  defp get_connected_nodes(state) do
    # TODO: fix
    Enum.filter(state.nodes, fn({_label, value}) ->
      match?(%{conn: _conn}, value)
    end)
  end

  defp get_conn(id, state) do
    # TODO: id must be unique
    # TODO: error if status is not :started
    active_cluster = get_active_cluster(state.clusters)
    node = Enum.find(active_cluster.nodes, fn(node) ->
      match?(%{id: id}, node)
    end)
    node.conn
  end

  def get_active_cluster(clusters) do
    Enum.find(clusters, fn(cluster) ->
      match?(%Cluster{active: true}, cluster)
    end)
  end

  defp get_cluster_by_id(id, clusters) do
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
          %CNode{
            id: :manager,
            label: "Manager",
            role: :manager,
            host: "192.168.99.100",
            cert_path: "/home/pablo/.docker/machine/machines/cluster1-node1"
          },
          %CNode{
            id: :worker1,
            label: "Worker1",
            role: :worker,
            host: "192.168.99.101",
            cert_path: "/home/pablo/.docker/machine/machines/cluster1-node2"
          },
        ]
      },
    ]
  end

  defp update_active_cluster(cluster, clusters) do
    index = Enum.find_index(clusters, fn(c) -> c.id == cluster.id end)
    [cluster] ++ List.delete_at(clusters, index)
  end

  defp activate_cluster(cluster) do
    nodes = start_nodes(cluster)
    %Cluster{cluster | active: true, nodes: nodes}
  end

  defp start_nodes(cluster) do
    for node <- cluster.nodes do
      case start_node(node) do
        {:ok, status, conn} ->
          %CNode{node | conn: conn, status: status}
        {:error, msg} ->
          %CNode{node | status: :failed, status_msg: msg}
      end
    end
  end

  defp start_node(%{host: host, port: port, cert_path: cert_path, id: id} = cluster) do
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

end
