defmodule Rotterdam.ClusterView do
  use Rotterdam.Web, :view

  def render("index.json", %{clusters: clusters}), do: clusters

end
