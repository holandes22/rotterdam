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

  defp broadcast_services do
    services = ClusterManager.services()
    Endpoint.broadcast! "state:docker", "services", %{services: services}
  end

  defp broadcast(%{type: :container, action: "start"}), do: broadcast_services()
  defp broadcast(%{type: :container, action: "stop"}), do: broadcast_services()
  defp broadcast(_), do: :ok

end