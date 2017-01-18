defmodule Rotterdam.Event.Docker.ProducerConsumer do
  alias Experimental.GenStage
  alias Rotterdam.ClusterManager

  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_events(events, _from, state) do
    {:noreply, events, state}
  end

end
