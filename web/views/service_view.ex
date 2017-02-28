defmodule Rotterdam.ServiceView do
  use Rotterdam.Web, :view

  def render("show.json", %{service: service}), do: service

end
