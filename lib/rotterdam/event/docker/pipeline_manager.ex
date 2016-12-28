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

    state = for params <- nodes, into: %{} do
      {_, _, _, label} = params
      Process.send_after self(), {:start_node, params}, 500
      {label, :starting}
    end
    {:ok, state}
  end

  def status, do: GenServer.call(__MODULE__, :status)

  # GenServer callbacks
  # -------------------

  def handle_info({:start_node, params}, state) do
    {host, port, cert_path, label} = params
    new_state = case Docker.client(host, port, cert_path) do
      {:ok, client} ->
        start_producer(client, label)
        Logger.info "Docker producer from host #{host} started"
        Map.put(state, label, :started)
      {:error, msg} ->
        Logger.error msg
        Map.put(state, label, :failed)
    end
    {:noreply, new_state}
  end

  def handle_call(:status, _from, state), do: {:reply, state, state}

  defp start_producer(client, label) do
    consumer_pid = Process.whereis(Consumer)
    producer_worker = worker(Producer, [client, label], id: "producer_#{Atom.to_string(label)}")
    response = Supervisor.start_child(PipelineSupervisor, producer_worker)
    producer_pid = case response do
      {:ok, pid} ->
        pid
      {:error, {:already_started, pid}} ->
        pid
    end
    GenStage.sync_subscribe(consumer_pid, to: producer_pid)
  end

end
