defmodule Rotterdam.EventChannel do
  use Rotterdam.Web, :channel

  intercept ["event"]

  def join("events:docker", _params, socket) do
    {:ok, socket}
  end

  def handle_in("event", payload, socket) do
    broadcast! socket, "event", payload
    {:noreply, socket}
  end

  def handle_out("event", payload, socket) do
    push socket, "event", payload
    {:noreply, socket}
  end

  def terminate({:shutdown, :closed}, socket) do
    IO.puts "Terminating"
  end
end
