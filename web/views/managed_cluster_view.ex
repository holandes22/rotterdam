defmodule Rotterdam.ManagedClusterView do
  use Rotterdam.Web, :view

  def render("index.json", %{clusters: clusters}), do: clusters

  def render("status.json", %{cluster_status: status}), do: status

end
