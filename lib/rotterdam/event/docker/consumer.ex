defmodule Rotterdam.Event.Docker.Consumer do
  alias Experimental.GenStage

  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [Rotterdam.Event.Docker.Producer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect event
      Rotterdam.Endpoint.broadcast! "room:docker", "event", event
    end

    {:noreply, [], state}
  end

end
