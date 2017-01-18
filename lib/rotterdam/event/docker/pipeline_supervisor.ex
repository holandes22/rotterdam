defmodule Rotterdam.Event.Docker.PipelineSupervisor do
  use Supervisor

  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_params) do

    children = [
      worker(Rotterdam.Event.Docker.ProducerConsumer, []),
      worker(Rotterdam.Event.Docker.Consumer, []),
      worker(Rotterdam.Event.Docker.State, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
