defmodule Rotterdam.Event.Docker.Producer do
  use GenStage

  alias Rotterdam.Event


  def start_link(conn, label) do
    GenStage.start_link(__MODULE__, {conn, label})
  end

  def init({conn, label}) when is_atom(label) do
    init({conn, Atom.to_string(label)})
  end
  def init({conn, label}) do
    Dox.events(conn, self())
    {:producer, {label, []}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_info({:hackney_response, _ref, chunk}, state) when is_binary(chunk) do
    {label, events} = state
    event = chunk
      |> Poison.decode!()
      |> Event.normalize(label)

    events = [event] ++ events
    {:noreply, [event], {label, events}}
  end
  def handle_info(_message, state), do: {:noreply, [], state}

  def handle_demand(demand, {label, events}) do
    events = Enum.slice(events, 0..demand)
    {:noreply, events, {label, events}}
  end


end
