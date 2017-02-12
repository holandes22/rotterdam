defmodule Rotterdam.ServiceView do
  use Rotterdam.Web, :view

  def render("show.json", %{service: service}), do: service

  def render("scripts.html", assigns) do
    ~E"""
    <script src="<%= static_path(@conn, "/js/services.js") %>"></script>
    """
  end
end
