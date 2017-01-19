defmodule Rotterdam.Event.Docker.PipelineSupervisor do
  use Supervisor

  require Logger


  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_params) do

    children = [
      worker(Rotterdam.Event.Docker.EventsBroadcast, []),
      worker(Rotterdam.Event.Docker.StateBroadcast, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
