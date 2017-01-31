defmodule Rotterdam.Node do

  defstruct id: nil,
            created_at: nil,
            updated_at: nil,
            hostname: nil,
            role: nil,
            availability: nil,
            nano_cpus: 0,
            memory_bytes: 0,
            state: nil,
            leader: false,
            reachability: nil,
            addr: nil


  def normalize(nodes) when is_list(nodes) do
    Enum.map(nodes, &normalize(&1))
  end
  def normalize(%{"ManagerStatus" => manager_status} = node) do
    %{
      "Leader" => leader,
      "Reachability" => reachability,
      "Addr" => addr
    } = manager_status

    get_node(node)
      |> Map.put(:leader, leader)
      |> Map.put(:reachability, reachability)
      |> Map.put(:addr, addr)

  end
  def normalize(node), do: get_node(node)

  defp get_node(node) do
    %{
      "ID" => id,
      "CreatedAt" => created_at,
      "UpdatedAt" => updated_at,
      "Description" => %{
        "Hostname" => hostname,
        "Resources" => %{
          "NanoCPUs" => nano_cpus,
          "MemoryBytes" => memory_bytes
        }
      },
      "Spec" => %{
        "Role" => role,
        "Availability" => availability
      },
      "Status" => %{
        "State" => state
      }
    } = node

    %__MODULE__{
      id: id,
      created_at: created_at,
      updated_at: updated_at,
      hostname: hostname,
      role: role,
      availability: availability,
      nano_cpus: nano_cpus,
      memory_bytes: memory_bytes,
      state: state
    }
  end

end
