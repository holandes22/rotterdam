defmodule Rotterdam.StateChannel do
  use Rotterdam.Web, :channel
  alias Rotterdam.ClusterManager

  intercept ["services"]

  def join("state:docker", %{"init" => "services"}, socket) do
    services = ClusterManager.services()
    {:ok, services, socket}
  end

  def handle_out("services", payload, socket) do
    push socket, "services", payload
    {:noreply, socket}
  end

  def terminate({:shutdown, :closed}, _socket) do
    IO.puts "Terminating"
  end
end
