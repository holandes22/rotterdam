defmodule Docker.Spec.Service do

  alias Docker.Spec.TaskTemplate
  import Docker.Spec.Utils, only: [format_keys: 1]

  defstruct name: nil,
    task_template: %TaskTemplate{},
    mode: %{
      replicated: %{
        replicas: 1
      }
    },
    labels: %{}

  def config_struct(name, image, replicas \\ 1) do
    %__MODULE__{name: name}
      |> format_keys
      |> put_in(["Mode", "Replicated", "Replicas"], replicas)
      |> put_in(["TaskTemplate", "ContainerSpec", "Image"], image)
  end
end
