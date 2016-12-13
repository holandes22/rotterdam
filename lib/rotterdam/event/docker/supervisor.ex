defmodule Rotterdam.Event.Docker.Supervisor do
  use Supervisor

  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    client1 = get_client("192.168.99.100", "2376", "/home/pablo/.docker/machine/machines/cluster1-node1")
    client2 = get_client("192.168.99.101", "2376", "/home/pablo/.docker/machine/machines/cluster1-node2")
    client3 = get_client("192.168.99.102", "2376", "/home/pablo/.docker/machine/machines/cluster1-node3")

    children = [
      worker(Rotterdam.Event.Docker.Producer, [client1, :manager], id: "producer_1"),
      worker(Rotterdam.Event.Docker.Producer, [client2, :worker1], id: "producer_2"),
      worker(Rotterdam.Event.Docker.Producer, [client3, :worker2], id: "producer_3"),
      worker(Rotterdam.Event.Docker.Consumer, [], id: "consumer_1"),
      worker(Rotterdam.Event.Docker.Consumer, [], id: "consumer_5"),
      worker(Rotterdam.Event.Docker.Consumer, [], id: "consumer_6"),
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp get_client(host, port, cert_path) do
    case Docker.client(host, port, cert_path) do
      {:ok, client} ->
        Logger.info "Docker client succesfully connected to host #{host}"
        client
      {:error, msg} ->
        Logger.error msg
        exit msg
    end
  end

end
