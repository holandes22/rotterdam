defmodule Rotterdam.Event.Docker.Producer do
  alias Experimental.GenStage

  use GenStage

  def start_link(client, label) do
    GenStage.start_link(__MODULE__, {client, label})
  end

  def init({client, label}) when is_atom(label) do
    init({client, Atom.to_string(label)})
  end
  def init({client, label}) do
    Docker.events(client, self)
    {:producer, {label, []}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_info({:hackney_response, _ref, chunk}, state) when is_binary(chunk) do
    {label, events} = state
    event = chunk
      |> Poison.decode!()
      |> Map.put("RotterdamNodeLabel", label)
    events = [event] ++ events
    {:noreply, events, {label, events}}
  end
  def handle_info(_message, state), do: {:noreply, [], state}

  def handle_demand(demand, {label, events}) do
    events = Enum.slice(events, 0..demand)
    {:noreply, events, {label, events}}
  end
end
