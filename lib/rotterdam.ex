defmodule Rotterdam do
  use Application
  require Logger

  alias Experimental.GenStage

  def start(_type, _args) do
    import Supervisor.Spec
    children = [
      supervisor(Rotterdam.Repo, []),
      supervisor(Rotterdam.Endpoint, []),
      supervisor(Rotterdam.Event.Docker.PipelineSupervisor, []),
      worker(Rotterdam.ClusterManager, [])
    ]

    opts = [strategy: :one_for_one, name: Rotterdam.Supervisor]
    Supervisor.start_link(children, opts)

  end

  def config_change(changed, _new, removed) do
    Rotterdam.Endpoint.config_change(changed, removed)
    :ok
  end

end
