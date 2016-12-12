defmodule Rotterdam do
  use Application
  require Logger

  alias Experimental.GenStage

  def start(_type, _args) do
    import Supervisor.Spec

    client1 = Docker.client("192.168.99.100", "2376", "/home/pablo/.docker/machine/machines/cluster1-node1")
    client2 = Docker.client("192.168.99.101", "2376", "/home/pablo/.docker/machine/machines/cluster1-node2")
    client3 = Docker.client("192.168.99.102", "2376", "/home/pablo/.docker/machine/machines/cluster1-node3")

    children = [
      supervisor(Rotterdam.Repo, []),
      supervisor(Rotterdam.Endpoint, []),
      worker(Rotterdam.Event.Docker.Producer, [client1, :manager], id: "producer_1"),
      worker(Rotterdam.Event.Docker.Producer, [client2, :worker1], id: "producer_2"),
      worker(Rotterdam.Event.Docker.Producer, [client3, :worker2], id: "producer_3"),
      worker(Rotterdam.Event.Docker.Consumer, [], id: "consumer_4"),
      worker(Rotterdam.Event.Docker.Consumer, [], id: "consumer_5"),
      worker(Rotterdam.Event.Docker.Consumer, [], id: "consumer_6"),
    ]

    opts = [strategy: :one_for_one, name: Rotterdam.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)
    children = Supervisor.which_children(pid)
    producers = filter_stages(children, Rotterdam.Event.Docker.Producer)
    consumers = filter_stages(children, Rotterdam.Event.Docker.Consumer)
    build_pipeline(producers, consumers)
    {:ok, pid}
  end

  def build_pipeline(producers, consumers) do
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
