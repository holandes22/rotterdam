defmodule Rotterdam do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    client = Docker.client("192.168.99.100", "2376", "/home/pablo/.docker/machine/machines/cluster1-node1")

    children = [
      supervisor(Rotterdam.Repo, []),
      supervisor(Rotterdam.Endpoint, []),
      worker(Rotterdam.Event.Docker.Producer, [client, :manager]),
      worker(Rotterdam.Event.Docker.Consumer, []),
    ]

    opts = [strategy: :one_for_one, name: Rotterdam.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def pipeline_workers do
    Application.get_env(:rotterdam, :cluster)
  end

  def config_change(changed, _new, removed) do
    Rotterdam.Endpoint.config_change(changed, removed)
    :ok
  end

end
