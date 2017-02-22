defmodule Rotterdam.ClusterView do
  use Rotterdam.Web, :view

  def render("index.json", %{cluster: cluster}), do: cluster

end
