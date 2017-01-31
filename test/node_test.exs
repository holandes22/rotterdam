defmodule Rotterdam.NodeTest do
  use ExUnit.Case, async: true

  alias Rotterdam.Node

  @node %{
    "CreatedAt" => "2016-12-07T09:03:36.802762256Z",
    "UpdatedAt" => "2017-01-30T13:58:10.103378479Z",
    "Description" => %{
      "Engine" => %{
        "EngineVersion" => "1.12.3",
        "Labels" => %{"provider" => "virtualbox"},
        "Plugins" => [
          %{"Name" => "bridge", "Type" => "Network"},
          %{"Name" => "local", "Type" => "Volume"}
        ]
      },
      "Hostname" => "cluster1-node1",
      "Platform" => %{"Architecture" => "x86_64", "OS" => "linux"},
      "Resources" => %{"MemoryBytes" => 1044140032, "NanoCPUs" => 1000000000}
    },
    "ID" => "5l6t3k8jqfr97ba16kxsi11do",
    "ManagerStatus" => %{
      "Addr" => "192.168.99.100:2377",
      "Leader" => true,
      "Reachability" => "reachable"
    },
    "Spec" => %{"Availability" => "active", "Role" => "manager"},
    "Status" => %{"State" => "ready"},
    "Version" => %{"Index" => 1855}
  }

  @node_with_no_manager_status %{
    "CreatedAt" => "2016-12-07T09:03:37.994559215Z",
    "UpdatedAt" => "2017-01-30T13:58:10.099625339Z",
    "Description" => %{
      "Engine" => %{
        "EngineVersion" => "1.12.3",
        "Labels" => %{"provider" => "virtualbox"},
      },
      "Hostname" => "cluster1-node2",
      "Platform" => %{"Architecture" => "x86_64", "OS" => "linux"},
      "Resources" => %{"MemoryBytes" => 1044140032, "NanoCPUs" => 1000000000}
    },
    "ID" => "4fughsnlgfe7jdve6kvrnzot6",
    "Spec" => %{"Availability" => "active", "Role" => "worker"},
    "Status" => %{
      "Message" => "heartbeat failure for node in unknown state",
      "State" => "down"
    },
    "Version" => %{"Index" => 1851}
  }

  test "normalize docker node" do
    node = Node.normalize(@node)
    assert node.hostname == "cluster1-node1"
    assert node.nano_cpus == 1_000_000_000
    assert node.state == "ready"
    assert node.role == "manager"
    assert node.leader
  end

  test "normalize docker node with no manager status" do
    node = Node.normalize(@node_with_no_manager_status)
    assert node.hostname == "cluster1-node2"
    assert node.state == "down"
    assert node.role == "worker"
    refute node.leader

  end


end
