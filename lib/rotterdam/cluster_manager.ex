defmodule Rotterdam.ClusterManager do
  use GenServer

  alias Experimental.GenStage
  alias Rotterdam.Event.Docker.{Producer, Consumer, PipelineSupervisor}
  import Supervisor.Spec, only: [worker: 3]
  require Logger


  # Public API
  # ----------

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_params) do
    nodes = [
      {"192.168.99.100", "2376", "/home/pablo/.docker/machine/machines/cluster1-node1", :manager},
      #{"192.168.99.101", "2376", "/home/pablo/.docker/machine/machines/cluster1-node2", :worker1},
      #{"192.168.99.102", "2376", "/home/pablo/.docker/machine/machines/cluster1-node3", :worker2},
    ]

    state = schedule_work(nodes)
    {:ok, state}
  end

  def status, do: GenServer.call(__MODULE__, :status)

  def conn(label), do: GenServer.call(__MODULE__, {:conn, label})

  # GenServer callbacks
  # -------------------

  def handle_info({:start_node, params}, state) do
    {host, port, cert_path, label} = params
    status = start_node(host, port, cert_path, label)

    {:noreply, Map.put(state, label, status)}
  end

  def handle_call(:status, _from, state), do: {:reply, state, state}

  def handle_call({:conn, label}, _from, state) do
    %{^label => %{conn: conn}} = state
    {:reply, conn, state}
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
        start_producer(conn, label)
        Logger.info "Docker producer from host #{host} started"
        %{status: :started, conn: conn}
      {:error, msg} ->
        Logger.error msg
        %{status: :failed, error: msg}
    end
  end

  defp start_producer(conn, label) do
    consumer_pid = Process.whereis(Consumer)
    child = worker(Producer, [conn, label], id: "producer_#{Atom.to_string(label)}")
    case Supervisor.start_child(PipelineSupervisor, child) do
      {:ok, producer_pid} ->
        GenStage.sync_subscribe(consumer_pid, to: producer_pid)
      {:error, {:already_started, producer_pid}} ->
        GenStage.sync_subscribe(consumer_pid, to: producer_pid)
    end
  end

end
