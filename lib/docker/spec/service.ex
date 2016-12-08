defmodule Docker.Spec.Service do

  alias Docker.Spec.TaskTemplate

  defstruct name: nil,
    task_template: %TaskTemplate{},
    mode: %{
      replicated: %{
        replicas: 1
      }
    },
    labels: %{}


  def config_struct(name, image) do
    config = %__MODULE__{name: name}
    put_in(config.task_template.container_spec.image, image)
  end
end
