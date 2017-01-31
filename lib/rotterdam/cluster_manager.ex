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
    params = [
      {"192.168.99.100", "2376", "/home/pablo/.docker/machine/machines/cluster1-node1", :manager},
      #{"192.168.99.101", "2376", "/home/pablo/.docker/machine/machines/cluster1-node2", :worker1},
      #{"192.168.99.102", "2376", "/home/pablo/.docker/machine/machines/cluster1-node3", :worker2},
    ]

    state = schedule_work(params)
    {:ok, state}
  end

  def status, do: GenServer.call(__MODULE__, :status)

  def conn(label), do: GenServer.call(__MODULE__, {:conn, label})

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def services, do: GenServer.call(__MODULE__, :services)

  def containers, do: GenServer.call(__MODULE__, :containers)

  # GenServer callbacks
  # -------------------

  def handle_info({:start_node, params}, state) do
    {host, port, cert_path, label} = params
    status = start_node(host, port, cert_path, label)

    {:noreply, Map.put(state, label, status)}
  end

  def handle_call(:status, _from, state), do: {:reply, state, state}
  def handle_call({:conn, label}, _from, state) do
    conn = get_conn(label, state)
    {:reply, conn, state}
  end
  def handle_call(:nodes, _from, state) do
    {:ok, nodes} = get_conn(:manager, state) |> Dox.nodes()
    nodes = Node.normalize(nodes)
    {:reply, nodes, state}
  end
  def handle_call(:services, _from, state) do
    conn = get_conn(:manager, state)
    services = conn
      |> Dox.services()
      |> ok()
      |> Service.normalize()

    {:reply, services, state}
  end
  def handle_call(:containers, _from, state) do
    {:reply, containers_per_node(state), state}
  end

  defp ok({:ok, value}), do: value

  defp containers_per_node(state)do
    for {label, _value} <- state, into: [] do
      {:ok, containers} = get_conn(label, state) |> Dox.containers()
      %{node: label, containers: containers}
    end
  end

  defp get_conn(label, state) do
    %{^label => %{conn: conn}} = state
    conn
  end

  defp schedule_work(nodes) do
    for params <- nodes, into: %{} do
      {_, _, _, label} = params
      Process.send_after self(), {:start_node, params}, 300
      {label, :starting}
    end
  end

  defp start_node(host, port, cert_path, label) do
    case Dox.conn(host, port, cert_path) do
      {:ok, conn} ->
        create_pipeline(conn, label)
        Logger.info "Docker producer from host #{host} started"
        %{status: :started, conn: conn}
      {:error, msg} ->
        Logger.error "Failed to start #{host}. #{msg}"
        %{status: :failed, error: msg}
    end
  end

  defp create_pipeline(conn, label) do
    id = "producer_" <> Atom.to_string(label)
    child = worker(Producer, [conn, label], id: id)

    case Supervisor.start_child(PipelineSupervisor, child) do
      {:ok, pid} ->
        create_pipeline(pid)
      {:error, {:already_started, pid}} ->
        create_pipeline(pid)
    end
  end
  defp create_pipeline(producer) when is_pid(producer) do
    events_pid = Process.whereis(EventsBroadcast)
    state_pid = Process.whereis(StateBroadcast)

    GenStage.sync_subscribe(events_pid, to: producer)
    GenStage.sync_subscribe(state_pid, to: producer)
  end

end
