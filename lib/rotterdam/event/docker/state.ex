defmodule Rotterdam.Event.Docker.State do
  alias Experimental.GenStage
  alias Rotterdam.{ClusterManager, Endpoint}

  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state}
  end

  def handle_events(events, _from, state) do
    IO.inspect events, label: "GOT EVENTS"
    hd(events) |> broadcast_state()

    {:noreply, [], state}
  end

  defp broadcast_state(%Event{type: "container", action: action}) do
    IO.inspect action, label: "GOT ACTION"
    if Enum.member?(["start", "stop"], action) do
        {:ok, services} = ClusterManager.conn(:manager) |> Dox.services()
        Endpoint.broadcast! "state:docker", "services", %{services: services}
    end
  end
  defp broadcast_state(_), do: :ok

end
