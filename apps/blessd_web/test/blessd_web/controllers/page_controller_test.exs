defmodule BlessdWeb.PageControllerTest do
  use BlessdWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Be Blessd!"
  end
end
