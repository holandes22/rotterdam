defmodule Rotterdam.Service do

  defstruct id: nil,
            created_at: nil,
            updated_at: nil,
            name: nil,
            replicas: 0,
            image: nil


  def normalize(services) when is_list(services) do
    Enum.map(services, &normalize(&1))
  end
  def normalize(service) do
    %{
      "ID" => id,
      "CreatedAt" => created_at,
      "UpdatedAt" => updated_at,
      "Spec" => %{
        "Name" => name,
        "Mode" => %{
          "Replicated" => %{
            "Replicas" => replicas
          }
        },
        "TaskTemplate" => %{
          "ContainerSpec" => %{
            "Image" => image
          }
        }
      },
    } = service

    %__MODULE__{
      id: id,
      created_at: created_at,
      updated_at: updated_at,
      name: name,
      replicas: replicas,
      image: image
    }

  end

end
