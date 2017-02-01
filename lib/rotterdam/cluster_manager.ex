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
    {:ok, %{}}
  end

  def cluster_status, do: GenServer.call(__MODULE__, :cluster_status)

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def services, do: GenServer.call(__MODULE__, :services)

  def containers_per_node, do: GenServer.call(__MODULE__, :containers_per_node)

  def connect(cluster), do: GenServer.call(__MODULE__, {:connect, cluster})

  # GenServer callbacks
  # -------------------

  def handle_call(:cluster_status, _from, state) do
    response = for {cluster, value} <- state, into: %{} do
      {cluster, value.status}
    end
    {:reply, response, state}
  end

  def handle_call({:connect, cluster}, _from, _state) do
    state = start_nodes(cluster)

    {:reply, state, state}
  end

  def handle_call(:nodes, _from, %{}), do: {:reply, [], %{}}
  def handle_call(:nodes, _from, state) do
    conn = get_conn(:manager, state)
    response =
      conn
      |> Dox.nodes()
      |> ok()
      |> Node.normalize()

    {:reply, response, state}
  end

  def handle_call(:services, _from, %{}), do: {:reply, [], %{}}
  def handle_call(:services, _from, state) do
    conn = get_conn(:manager, state)
    response =
      conn
      |> Dox.services()
      |> ok()
      |> Service.normalize()

    {:reply, response, state}
  end

  def handle_call(:containers_per_node, _from, %{}), do: {:reply, [], %{}}
  def handle_call(:containers_per_node, _from, state) do
    {:reply, containers_per_node(state), state}
  end

  defp ok({:ok, value}), do: value

  defp containers_per_node(state)do
    for {label, _value} <- state, into: [] do
      conn = get_conn(label, state)
      containers =
        conn
        |> Dox.containers()
        |> ok()
      %{node: label, containers: containers}
    end
  end

  defp get_conn(label, state) do
    %{^label => %{conn: conn}} = state
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
