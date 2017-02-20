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
    {:ok, %{active_cluster: nil, nodes: %{}}}
  end

  def cluster_status, do: GenServer.call(__MODULE__, :cluster_status)

  def active_cluster, do: GenServer.call(__MODULE__, :active_cluster)

  def clusters, do: GenServer.call(__MODULE__, :clusters)

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def services, do: GenServer.call(__MODULE__, :services)
  def services(id), do: GenServer.call(__MODULE__, {:services, id})

  def containers_per_node, do: GenServer.call(__MODULE__, :containers_per_node)

  def connect(cluster), do: GenServer.call(__MODULE__, {:connect, cluster})

  # GenServer callbacks
  # -------------------

  def handle_call(:cluster_status, _from, %{active_cluster: nil} = state) do
    {:reply, {:inactive, nil}, state}
  end
  def handle_call(:cluster_status, _from, state) do
    status = cluster_status(state)

    {:reply, {:active, status}, state}
  end

  def handle_call({:connect, cluster}, _from, _state) do
    nodes = start_nodes(cluster)
    state = %{active_cluster: cluster, nodes: nodes}
    status = cluster_status(state)

    {:reply, status, state}
  end

  def handle_call(:active_cluster, _from, %{active_cluster: cluster} = state) do
    {:reply, cluster, state}
  end

  def handle_call(:clusters, _from, state) do
    %{active_cluster: active_cluster} = state
    cluster1 = "cluster1"
    cluster2 = "cluster2"

    clusters = [
      %{
          id: cluster1,
          label: "Alpha",
          active: active_cluster == cluster1,
        },
      %{
          id: cluster2,
          label: "Beta",
          active: active_cluster == cluster2,
        }
    ]
    {:reply, clusters, state}
  end

  def handle_call(:nodes, _from, %{active_cluster: nil} = state) do
    {:reply, [], state}
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

  def handle_call(:services, _from, %{active_cluster: nil} = state) do
    # TODO: return error if called when cluster is not active
    {:reply, [], state}
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

  def handle_call(:containers_per_node, _from, %{active_cluster: nil} = state) do
    {:reply, [], state}
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

  defp cluster_status(state) do
    %{
      id: state.active_cluster,
      label: state.active_cluster,
      nodes: nodes_status(state.nodes)
    }
  end

  defp nodes_status(nodes) do
    for {node, value} <- nodes do
      %{label: node, status: value.status}
    end
  end

  defp get_connected_nodes(state) do
    Enum.filter(state.nodes, fn({_label, value}) ->
      match?(%{conn: _conn}, value)
    end)
  end

  defp get_conn(label, state) do
    %{nodes: %{^label => %{conn: conn}}} = state
    conn
  end

  defp get_cluster_params(_cluster) do
    [
      {"192.168.99.100", "2376", "/home/pablo/.docker/machine/machines/cluster1-node1", :manager},
      {"192.168.99.101", "2376", "/home/pablo/.docker/machine/machines/cluster1-node2", :worker1},
      #{"192.168.99.102", "2376", "/home/pablo/.docker/machine/machines/cluster1-node3", :worker2},
    ]
  end

  defp start_nodes(cluster) do
    params_list = get_cluster_params(cluster)

    for params <- params_list, into: %{} do
      {host, port, cert_path, label} = params
      status = start_node(host, port, cert_path, label)
      {label, status}
    end
  end

  defp start_node(host, port, cert_path, label) do
    case Dox.conn(host, port, cert_path) do
      {:ok, conn} ->
        create_event_pipeline(conn, label)
        Logger.info "Docker producer from host #{host} started"
        %{status: :started, conn: conn}
      {:error, msg} ->
        Logger.error "Failed to start #{host}. #{msg}"
        %{status: :failed, error: msg}
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
