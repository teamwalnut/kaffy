defmodule ApiWeb.DashboardTest do
  use ApiWeb.ConnCase, async: true

  alias Api.Accounts
  alias ApiWeb.UserAuth
  import Api.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, ApiWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  describe "/dashboard" do
    test "returns 401 for non admins", %{user: user, conn: conn} do
      conn = UserAuth.log_in_user(conn, user)

      conn = get(conn, "/dashboard")
      assert response(conn, 401) == "Unauthorized"
    end

    test "returns 200 with content for admins", %{user: user, conn: conn} do
      user = Accounts.make_admin!(user)
      conn = UserAuth.log_in_user(conn, user)

      conn = get(conn, "/dashboard")
      assert redirected_to(conn) =~ "/dashboard/"
    end
  end
end
