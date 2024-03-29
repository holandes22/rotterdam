defmodule Rotterdam.Event.Docker.EventsBroadcast do
  use GenStage

  alias Rotterdam.Endpoint


  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state}
  end

  def handle_events([event | _tail], _from, state) do
    Endpoint.broadcast! "events:docker", "event", event

    {:noreply, [], state}
  end

end
