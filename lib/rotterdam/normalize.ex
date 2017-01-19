defmodule Rotterdam.Normalize do

  alias Rotterdam.Event

  def normalize_event(%{"Type" => "container"} = event, node_label) do
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
      type: :container,
      container: container,
      action: action,
      service_name: service_name,
      service_id: service_id,
      image: image,
      time: time
    }
  end
  def normalize_event(%{"Type" => "image", "id" => id, "time" => time}, label) do
    %Event{
      node_label: label,
      type: :image,
      image: id,
      time: time
    }
  end
  def normalize_event(%{"Type" => "network"} = event, node_label) do
    %{
      "time" => time,
      "Action" => action,
      "Actor" => %{"Attributes" => %{"container" => container}}
    } = event

    %Event{
      node_label: node_label,
      type: :network,
      container: container,
      action: action,
      time: time
    }
  end
  def normalize_event(event, node_label) do
    IO.inspect event, label: "Unknown event type"
    %Event{
      node_label: node_label,
      type: :unknown,
    }
  end

end
