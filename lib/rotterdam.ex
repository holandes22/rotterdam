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
      worker(Rotterdam.Event.Docker.PipelineManager, [])
    ]

    opts = [strategy: :one_for_one, name: Rotterdam.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    # children = Supervisor.which_children(pid)
    # {Rotterdam.Event.Docker.Supervisor, spid, :supervisor, _type} = List.first(children)
    # children = Supervisor.which_children(spid)
    # producers = filter_stages(children, Rotterdam.Event.Docker.Producer)
    # consumers = filter_stages(children, Rotterdam.Event.Docker.Consumer)
    # build_event_pipeline(producers, consumers)
    {:ok, pid}
  end

  def build_event_pipeline(producers, consumers) do
    for {producer, consumer} <- List.zip([producers, consumers]),
        {prod_id, producer_pid, _type, _mod} = producer,
        {cons_id, consumer_pid, _type, _mod} = consumer do
      Logger.info("Subscribing consumer #{prod_id} to consumer #{cons_id}")
      GenStage.sync_subscribe(consumer_pid, to: producer_pid)
    end
  end

  def pipeline_workers do
    Application.get_env(:rotterdam, :cluster)
  end

  defp filter_stages(children, stage) do
    Enum.filter(children, fn(e) ->
      case e do
        {_id, _pid, _type, [^stage]} -> true
        _ -> false
      end
    end)
  end

  def config_change(changed, _new, removed) do
    Rotterdam.Endpoint.config_change(changed, removed)
    :ok
  end

end
