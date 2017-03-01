defmodule Rotterdam.ServiceView do
  use Rotterdam.Web, :view

  def render("show.json", %{service: service}), do: service

  def render("created.json", %{id: id}), do: id

end
