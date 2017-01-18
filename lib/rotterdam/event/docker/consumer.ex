defmodule Rotterdam.Event.Docker.Consumer do
  alias Experimental.GenStage
  alias Rotterdam.ClusterManager

  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state}
  end

  def handle_events(events, _from, state) do

    for event <- events do
      Rotterdam.Endpoint.broadcast! "events:docker", "event", event
    end
    {:ok, services} = ClusterManager.conn(:manager) |> Dox.services()
    Rotterdam.Endpoint.broadcast! "state:docker", "services", %{services: services}

    {:noreply, [], state}
  end

end
