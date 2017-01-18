defmodule Rotterdam.Event.Docker.Consumer do
  alias Experimental.GenStage
  alias Rotterdam.Endpoint

  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state}
  end

  def handle_events(events, _from, state) do
    Endpoint.broadcast! "events:docker", "event", hd(events)

    {:noreply, [], state}
  end

end
