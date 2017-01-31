defmodule Rotterdam.StateChannel do
  use Rotterdam.Web, :channel
  alias Rotterdam.ClusterManager

  intercept ["nodes", "services"]

  def join("state:docker", %{"init" => "services"}, socket) do
    services = ClusterManager.services()
    {:ok, services, socket}
  end
  def join("state:docker", %{"init" => "nodes"}, socket) do
    nodes = ClusterManager.nodes()
    {:ok, nodes, socket}
  end

  def handle_out("services", payload, socket) do
    push socket, "services", payload
    {:noreply, socket}
  end
  def handle_out("nodes", payload, socket) do
    push socket, "nodes", payload
    {:noreply, socket}
  end

  def terminate({:shutdown, :closed}, socket) do
    IO.puts "Terminating"
  end
end
