defmodule Rotterdam.Event do

  @null "null"

  defstruct node_label: @null,
            container: @null,
            type: @null,
            action: @null,
            service_name: @null,
            service_id: @null,
            image: @null,
            time: 0


  def normalize(%{"Type" => "container"} = event, node_label) do
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

    %__MODULE__{
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
  def normalize(%{"Type" => "image", "id" => id, "time" => time}, label) do
    %__MODULE__{
      node_label: label,
      type: :image,
      image: id,
      time: time
    }
  end
  def normalize(%{"Type" => "network"} = event, node_label) do
    %{
      "time" => time,
      "Action" => action,
      "Actor" => %{"Attributes" => %{"container" => container}}
    } = event

    %__MODULE__{
      node_label: node_label,
      type: :network,
      container: container,
      action: action,
      time: time
    }
  end
  def normalize(event, node_label) do
    IO.inspect event, label: "Unknown event type"
    %__MODULE__{
      node_label: node_label,
      type: :unknown,
    }
  end

end
