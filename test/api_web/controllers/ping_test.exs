defmodule ApiWeb.PingTest do
  use ApiWeb.ConnCase, async: true

  describe "/ping" do
    test "should respond with OK" do
      conn = get(build_conn(), "/ping")
      assert conn.resp_body =~ "OK"
    end
  end
end
