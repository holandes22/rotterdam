defmodule Rotterdam.PageControllerTest do
  use Rotterdam.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Welcome to Rotterdam!"
  end
end
