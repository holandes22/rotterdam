defmodule Rotterdam.ClusterManager do
  use GenServer

  require Logger

  import Supervisor.Spec, only: [worker: 3]

  alias Rotterdam.{Service, Node, Managed}
  alias Rotterdam.Event.Docker.PipelineSupervisor
  alias Rotterdam.Event.Docker.{Producer, EventsBroadcast, StateBroadcast}


  # Public API
  # ----------

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_params) do
    {:ok, %{cluster: nil, conns: nil}}
  end

  def cluster, do: GenServer.call(__MODULE__, :cluster)

  def connect(cluster \\ nil, opts \\ [start_event_pipeline: true]), do: GenServer.call(__MODULE__, {:connect, cluster, opts})

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def services, do: GenServer.call(__MODULE__, :services)
  def services(id), do: GenServer.call(__MODULE__, {:services, id})

  def create_service(name, image), do: GenServer.call(__MODULE__, {:create_service, name, image})

  def containers_per_node, do: GenServer.call(__MODULE__, :containers_per_node)

  def clear_conn, do: GenServer.call(__MODULE__, :clear_conn)

  # GenServer callbacks
  # -------------------

  def handle_call(:cluster, _from, %{cluster: cluster} = state) do
    {:reply, cluster, state}
  end

  def handle_call(:clear_conn, _from, _state) do
    Supervisor.stop(PipelineSupervisor, :normal)
    state = %{cluster: nil, conns: nil}

    {:reply, state, state}
  end

  def handle_call({:connect, cluster, [start_event_pipeline: start_event_pipeline]}, _from, _state) do
    cluster = cluster || cluster_config()

    state =
      cluster
      |> connect_cluster()
      |> get_state_from_connect_results(cluster)

    if start_event_pipeline do
      create_event_pipeline(state.conns)
      update_clients()
    end

    {:reply, state.cluster, state}
  end

  def handle_call(_, _from, %{conns: nil} = state), do: {:reply, {:error, :cluster_inactive}, state}
  def handle_call(_, _from, %{conns: []} = state), do: {:reply, {:error, :no_active_conns}, state}

  def handle_call(:nodes, _from, state) do
    reply =
      state
      |> get_conn()
      |> Dox.nodes()
      |> ok()
      |> Node.normalize()

    {:reply, {:ok, reply}, state}
  end

  def handle_call(:services, _from, state) do
    reply =
      state
      |> get_conn()
      |> Dox.services()
      |> ok()
      |> Service.normalize()

    {:reply, {:ok, reply}, state}
  end

  def handle_call({:services, id}, _from, state) do
    reply =
      state
      |> get_conn()
      |> Dox.services(id)
      |> ok()
      |> Service.normalize()

    {:reply, {:ok, reply}, state}
  end

  def handle_call({:create_service, name, image}, _from, state) do
    response =
      state
      |> get_conn()
      |> Dox.create_service(name, image)

    {:ok, %{"ID" => id}} = response

    {:reply, {:ok, id}, state}

  end

  def handle_call(:containers_per_node, _from, state) do
    {:reply, {:ok, containers_per_node(state)}, state}
  end

  defp ok({:ok, value}), do: value

  defp containers_per_node(state)do
    for %{conn: conn, node: node} <- state.conns, into: [] do
      containers =
        conn
        |> Dox.containers()
        |> ok()

      %{label: node.label, containers: containers}
    end
  end

  defp get_conn(state) do
    conn = get_conn_by_role(:manager, state.conns)
    conn.conn
  end

  defp get_conn_by_role(role, conns) do
    Enum.find(conns, &match?(%{node: %{role: ^role}}, &1))
  end

  defp get_state_from_connect_results(results, cluster) do
    nodes = Enum.map(results, fn(r) -> r.node end)
    conns = Enum.filter(results, fn(r) -> r.conn != nil end)

    cluster = %{cluster | nodes: nodes, connected: true}

    %{cluster: cluster, conns: conns}
  end

  defp connect_cluster(cluster) do
    for node <- cluster.nodes do
      case Dox.conn(node.host, node.port, node.cert_path) do
        {:ok, conn} ->
          Logger.info "Connection to #{node.host} was succesful"
          node = %{node | status: :started, status_msg: "Started"}

          %{node: node, conn: conn}
        {:error, msg} ->
          Logger.error "Failed to start #{node.host}. #{msg}"
          node = %{node | status: :failed, status_msg: msg}

          %{node: node, conn: nil}
      end
    end
  end

  defp update_clients() do
    state_pid = Process.whereis(StateBroadcast)
    send state_pid, :broadcast_all
  end

  defp create_event_pipeline(conns) when is_list(conns) do
    for %{conn: conn, node: node} <- conns do
      create_event_pipeline(conn, node.id, node.label)
      Logger.info "Docker producer for node #{node.label} (#{node.host}) started"
    end
  end
  defp create_event_pipeline(conn, node_id, label) do
    id = "producer_" <> Atom.to_string(node_id)
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

  defp cluster_config() do
    nodes =
      :rotterdam
      |> Application.get_env(:managed_nodes)
      |> Enum.map(&Map.merge(%Managed.Node{}, &1))

    %Managed.Cluster{nodes: nodes}
  end

end
