defmodule ApiWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ApiWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ApiWeb.ConnCase
      import ExUnit.CaptureLog
      import Hammox

      use Api.Fixtures

      alias ApiWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint ApiWeb.Endpoint
    end
  end

  setup tags do
    pid = Sandbox.start_owner!(Api.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    conn =
      conn
      |> Map.replace!(:secret_key_base, ApiWeb.Endpoint.config(:secret_key_base))
      |> Plug.Test.init_test_session(%{})

    user = Api.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Api.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  def expect_identity_reporing(user, company) do
    %{email: user_email, first_name: first_name, last_name: last_name} = user
    %{name: company_name} = company

    ApiWeb.Analytics.ProviderMock
    |> Hammox.expect(:identify, fn ^user_email,
                                   %{
                                     company: %{name: ^company_name},
                                     first_name: ^first_name,
                                     last_name: ^last_name
                                   } ->
      :ok
    end)
  end
end
