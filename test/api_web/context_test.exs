defmodule ApiWeb.ContextTest do
  use ApiWeb.ConnCase, async: true
  alias ApiWeb.Context
  import Api.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, ApiWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  describe "init/1" do
    test "calls init" do
      opts = %{:test => "123"}
      init = Context.init(opts)
      assert init == opts
    end
  end

  describe "call/2" do
    test "builds context with current_user", %{conn: conn, user: user} do
      conn = assign(conn, :current_user, user)
      conn = Context.call(conn, %{})

      assert conn.assigns[:current_user] ==
               conn.private[:absinthe][:context][:current_user]
    end

    test "builds context with no user or token", %{conn: conn, user: _user} do
      empty_context = %{}
      conn = Context.call(conn, %{})
      assert empty_context == conn.private[:absinthe][:context]
    end
  end
end
