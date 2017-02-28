defmodule Rotterdam.Event.Docker.StateBroadcast do
  use GenStage

  alias Rotterdam.{ClusterManager, Endpoint}

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state}
  end

  def handle_events([event | _tail], _from, state) do
    broadcast(event)

    {:noreply, [], state}
  end

  def handle_info(:broadcast_all, state) do
    spawn &broadcast_containers/0
    spawn &broadcast_services/0

    {:noreply, [], state}
  end

  defp broadcast_containers do
    {:ok, containers} = ClusterManager.containers_per_node()
    Endpoint.broadcast! "state:docker", "containers", %{containers: containers}
  end

  defp broadcast_services do
    {:ok, services} = ClusterManager.services()
    Endpoint.broadcast! "state:docker", "services", %{services: services}
  end

  defp broadcast(%{type: :container, action: "start"}) do
    broadcast_services()
    broadcast_containers()
  end
  defp broadcast(%{type: :container, action: "stop"}) do
    broadcast_services()
    broadcast_containers()
  end
  defp broadcast(_), do: :ok

end
