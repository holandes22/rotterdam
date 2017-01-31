defmodule Rotterdam.NodeView do
  use Rotterdam.Web, :view

  def render("scripts.html", assigns) do
    ~E"""
    <script src="<%= static_path(@conn, "/js/nodes.js") %>"></script>
    """
  end
end
