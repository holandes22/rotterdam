defmodule Rotterdam.StateChannel do
  use Rotterdam.Web, :channel
  alias Rotterdam.Event.Docker.PipelineManager

  intercept ["services"]

  def join("state:docker", _params, socket) do
    {:ok, services} = PipelineManager.conn(:manager) |> Dox.services()
    {:ok, services, socket}
  end

  def handle_out("services", payload, socket) do
    IO.inspect payload, label: "services payload"
    push socket, "services", payload
    {:noreply, socket}
  end

  def terminate({:shutdown, :closed}, socket) do
    IO.puts "Terminating"
  end
end
