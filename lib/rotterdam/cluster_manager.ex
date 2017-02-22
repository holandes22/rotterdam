# TODO: move to separate file and rename module to Rotterdam.Managed.*
defmodule Cluster do
  defstruct label: nil,
            connected: false,
            nodes: []
end


defmodule ManagedNode do
  defstruct id: nil,
            label: nil,
            role: nil,
            host: nil,
            port: "2376",
            cert_path: nil,
            status: :stopped,
            status_msg: ""
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
    cluster = get_configured_cluster()

    {:ok, %{cluster: cluster, conns: nil}}
  end

  def cluster, do: GenServer.call(__MODULE__, :cluster)

  def connect, do: GenServer.call(__MODULE__, :connect)

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def services, do: GenServer.call(__MODULE__, :services)
  def services(id), do: GenServer.call(__MODULE__, {:services, id})

  def containers_per_node, do: GenServer.call(__MODULE__, :containers_per_node)

  # GenServer callbacks
  # -------------------

  def handle_call(:cluster, _from, %{cluster: cluster} = state) do
    {:reply, cluster, state}
  end

  def handle_call(:connect, _from, %{cluster: cluster}) do
    state =
      cluster
      |> connect_cluster()
      |> get_state_from_connect_results(cluster)

    {:reply, state.cluster, state}
  end

  def handle_call(_, _from, %{conns: nil} = state), do: {:reply, {:error, :cluster_inactive}, state}
  def handle_call(_, _from, %{conns: []} = state), do: {:reply, {:error, :no_active_conns}, state}

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
    for %{conn: conn, label: label} <- state.conns, into: [] do
      containers =
        conn
        |> Dox.containers()
        |> ok()

      %{label: label, containers: containers}
    end
  end

  defp get_conn(state) do
    conn = get_conn_by_role(:manager, state.conns)
    conn.conn
  end

  defp get_conn_by_role(role, conns) do
    Enum.find(conns, fn(conn) ->
      match?(%{role: ^role}, conn)
    end)
  end

  defp get_configured_cluster() do
    %Cluster{
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
    }
  end

  defp get_state_from_connect_results(results, cluster) do
    nodes = for result <- results do
      %{result.node | status: result.status, status_msg: result.status_msg}
    end

    conns =
      results
      |> Enum.filter(fn(%{conn: conn}) -> conn != nil end)
      |> Enum.map(fn(%{conn: conn, node: %{id: id, label: label, role: role}}) ->
          %{id: id, label: label, role: role, conn: conn}
        end)

    cluster = %{cluster | nodes: nodes, connected: true}

    %{cluster: cluster, conns: conns}
  end

  defp connect_cluster(cluster) do
    for node <- cluster.nodes do
      case start_node(node) do
        {:ok, conn} ->
          %{node: node, conn: conn, status: :started, status_msg: "Started"}
        {:error, msg} ->
          %{node: node, conn: nil, status: :failed, status_msg: msg}
      end
    end
  end

  defp start_node(%{host: host, port: port, cert_path: cert_path, id: id, label: label}) do
    case Dox.conn(host, port, cert_path) do
      {:ok, conn} ->
        create_event_pipeline(conn, id, label)
        Logger.info "Docker producer from host #{host} started"
        {:ok, conn}
      {:error, msg} ->
        Logger.error "Failed to start #{host}. #{msg}"
        {:error, msg}
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

end
