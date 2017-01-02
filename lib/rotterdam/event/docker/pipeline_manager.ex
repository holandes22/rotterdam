defmodule Rotterdam.Event.Docker.PipelineManager do
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
      {"192.168.99.101", "2376", "/home/pablo/.docker/machine/machines/cluster1-node2", :worker1},
      {"192.168.99.102", "2376", "/home/pablo/.docker/machine/machines/cluster1-node3", :worker2},
    ]

    state = schedule_work(nodes)
    {:ok, state}
  end

  def status, do: GenServer.call(__MODULE__, :status)

  # GenServer callbacks
  # -------------------

  def handle_info({:start_node, params}, state) do
    {host, port, cert_path, label} = params
    status = start_node(host, port, cert_path, label)

    {:noreply, Map.put(state, label, status)}
  end

  def handle_call(:status, _from, state), do: {:reply, state, state}

  defp schedule_work(nodes) do
    for params <- nodes, into: %{} do
        {_, _, _, label} = params
        Process.send_after self(), {:start_nodes, params}, 300
        {label, :starting}
    end
  end

  defp start_node(host, port, cert_path, label) do
    case Docker.client(host, port, cert_path) do
      {:ok, client} ->
        start_producer(client, label)
        Logger.info "Docker producer from host #{host} started"
        %{status: :started}
      {:error, msg} ->
        Logger.error msg
        %{status: :failed, error: msg}
    end
  end

  defp start_producer(client, label) do
    consumer_pid = Process.whereis(Consumer)
    child = worker(Producer, [client, label], id: "producer_#{Atom.to_string(label)}")
    case Supervisor.start_child(PipelineSupervisor, child) do
      {:ok, producer_pid} ->
        GenStage.sync_subscribe(consumer_pid, to: producer_pid)
      {:error, {:already_started, producer_pid}} ->
        GenStage.sync_subscribe(consumer_pid, to: producer_pid)
    end
  end

end
