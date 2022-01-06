defmodule ApiWeb.SSOControllerTest do
  use ApiWeb.ConnCase, async: true

  import Hammox
  setup :verify_on_exit!

  setup [:setup_user, :setup_company, :setup_member]

  describe "GET /login/sso" do
    test "logins via google when provider is google", %{
      conn: conn
    } do
      conn = get(conn, Routes.sso_path(conn, :get), %{"provider" => "google"})

      assert redirected_to(conn) =~ "GoogleOAuth"
    end

    test "when SSO enabled, returns a redirect url", %{
      conn: conn,
      user: user,
      company: company
    } do
      domain = Api.SSO.domain_from_email(user.email)
      company_sso_fixture(company, domain: domain)
      conn = get(conn, Routes.sso_path(conn, :get), %{"email" => domain})
      assert json_response(conn, 200)["redirect"] =~ "https://api.workos.com/sso/authorize"
    end

    test "when SSO isn't enabled, return false", %{
      conn: conn,
      user: user
    } do
      domain = Api.SSO.domain_from_email(user.email)

      conn = get(conn, Routes.sso_path(conn, :get), %{"email" => domain})
      assert json_response(conn, 200)["redirect"] == nil
      assert json_response(conn, 200)["result"] == false
    end
  end

  describe "GET /login/sso/callback" do
    test "loggs in user if account already exists", %{conn: conn, user: user, company: company} do
      Tesla.Mock.mock(fn env ->
        case env.url do
          "https://api.workos.com/sso/token" ->
            %Tesla.Env{status: 200, body: %{"profile" => %{"email" => user.email}}}

          _ ->
            %Tesla.Env{status: 404, body: "NotFound"}
        end
      end)

      expect_identity_reporing(user, company)

      conn = get(conn, Routes.sso_path(conn, :callback), %{"code" => "1234"})
      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ Application.fetch_env!(:api, :app_url)
    end
  end
end
