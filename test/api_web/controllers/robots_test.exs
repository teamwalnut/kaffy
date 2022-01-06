defmodule ApiWeb.RobotsTest do
  use ApiWeb.ConnCase

  describe "robots.txt" do
    test "it's returned", %{conn: conn} do
      conn = get(conn, "/robots.txt")

      refute is_nil(text_response(conn, 200))
    end
  end
end
