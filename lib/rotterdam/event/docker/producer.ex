defmodule Event do

  @null "null"

  defstruct node_label: @null,
            container: @null,
            type: @null,
            action: @null,
            service_name: @null,
            service_id: @null,
            image: @null,
            time: 0

end

defmodule Rotterdam.Event.Docker.Producer do
  alias Experimental.GenStage

  use GenStage

  def start_link(conn, label) do
    GenStage.start_link(__MODULE__, {conn, label})
  end

  def init({conn, label}) when is_atom(label) do
    init({conn, Atom.to_string(label)})
  end
  def init({conn, label}) do
    Dox.events(conn, self())
    {:producer, {label, []}}
  end

  def handle_info({:hackney_response, _ref, chunk}, state) when is_binary(chunk) do
    {label, events} = state
    event = chunk
      |> Poison.decode!()
      |> normalize_event(label)

    events = [event] ++ events
    {:noreply, [event], {label, events}}
  end
  def handle_info(_message, state), do: {:noreply, [], state}

  def handle_demand(demand, {label, events}) do
    events = Enum.slice(events, 0..demand)
    {:noreply, events, {label, events}}
  end

  defp normalize_event(%{"Type" => "container"} = event, node_label) do
    %{
      "id" => container,
      "from" => image,
      "time" => time,
      "Action" => action,
      "Actor" => %{
        "Attributes" => %{
          "com.docker.swarm.service.id" => service_id,
          "com.docker.swarm.service.name" => service_name,
        }
      }
    } = event

    %Event{
      node_label: node_label,
      type: "container",
      container: container,
      action: action,
      service_name: service_name,
      service_id: service_id,
      image: image,
      time: time
    }
  end
  defp normalize_event(%{"Type" => "image"} = event, node_label) do
    %{"id" => image, "time" => time} = event
    %Event{
      node_label: node_label,
      type: "image",
      image: image,
      time: time
    }
  end
  defp normalize_event(%{"Type" => "network"} = event, node_label) do
    %{
      "time" => time,
      "Action" => action,
      "Actor" => %{"Attributes" => %{"container" => container}}
    } = event

    %Event{
      node_label: node_label,
      type: "network",
      container: container,
      action: action,
      time: time
    }
  end
  defp normalize_event(event, node_label) do
    IO.inspect event
    %Event{
      node_label: node_label,
      type: "unknown",
    }
  end



end
