defmodule Rotterdam.ContainerView do
  use Rotterdam.Web, :view

  def render("scripts.html", assigns) do
    ~E"""
    <script src="<%= static_path(@conn, "/js/containers.js") %>"></script>
    """
  end
end
