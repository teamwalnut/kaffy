defmodule ApiWeb.UserSessionControllerTest do
  use ApiWeb.ConnCase, async: true

  setup :verify_on_exit!

  setup [:setup_user, :setup_company, :setup_member]

  describe "POST /users/log_in" do
    test "logs the user in", %{
      conn: conn,
      company: company,
      user: user
    } do
      expect_identity_reporing(user, company)

      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
    end

    test "doesn't allow login in when the company is locked", %{
      conn: conn,
      company: company,
      user: user
    } do
      {:ok, _company} = Api.Companies.update_company(company, %{is_locked: true})

      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      response = json_response(conn, 401)
      assert response == %{"error" => "Invalid email or password"}
    end

    test "doesn't allow login when SSO is enabled for the email domain", %{
      conn: conn,
      company: company,
      user: user
    } do
      user_domain = Api.SSO.domain_from_email(user.email)
      company_sso_fixture(company, domain: user_domain)

      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      response = json_response(conn, 401)
      assert response == %{"error" => "Invalid email or password"}
    end

    test "logs the user in with remember me", %{
      conn: conn,
      company: company,
      user: user
    } do
      expect_identity_reporing(user, company)

      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["user_remember_me"]
      response = json_response(conn, 200)
      assert response == %{"ok" => "Logged in successfully"}
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      assert capture_log(fn ->
               conn =
                 post(conn, Routes.user_session_path(conn, :create), %{
                   "user" => %{"email" => user.email, "password" => "invalid_password"}
                 })

               response = json_response(conn, 401)
               assert response == %{"error" => "Invalid email or password"}
             end) =~ "Incorrect username/password"
    end
  end

  describe "POST /users/login_with_google" do
    test "logs the user in using google api", %{
      conn: conn,
      company: company,
      user: user
    } do
      expect_identity_reporing(user, company)

      Api.GoogleApi.ApiMock
      |> expect(:token_info, fn _token ->
        {:ok, %{"email" => user.email}}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer 123")
        |> post(Routes.user_session_path(conn, :create_google))

      assert get_session(conn, :user_token)
    end

    test "returns an error if the company is locked", %{
      conn: conn,
      company: company,
      user: user
    } do
      Api.GoogleApi.ApiMock
      |> expect(:token_info, fn _token ->
        {:ok, %{"email" => user.email}}
      end)

      {:ok, _company} = Api.Companies.update_company(company, %{is_locked: true})

      conn =
        conn
        |> put_req_header("authorization", "Bearer 123")
        |> post(Routes.user_session_path(conn, :create_google))

      response = json_response(conn, 401)
      assert response == %{"error" => "Error logging through google"}
    end

    test "returns an error if the company has SSO enabled", %{
      conn: conn,
      company: company,
      user: user
    } do
      user_domain = Api.SSO.domain_from_email(user.email)
      company_sso_fixture(company, domain: user_domain)
      # expect_identity_reporing(user, company)

      Api.GoogleApi.ApiMock
      |> expect(:token_info, fn _token ->
        {:ok, %{"email" => user.email}}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer 123")
        |> post(Routes.user_session_path(conn, :create_google))

      response = json_response(conn, 401)
      assert response == %{"error" => "Error logging through google"}
    end

    test "returns an error if trying to login with non-existing user", %{conn: conn} do
      Api.GoogleApi.ApiMock
      |> expect(:token_info, fn _token ->
        {:ok, %{"email" => "12233444"}}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer 123")
        |> post(Routes.user_session_path(conn, :create_google))

      response = json_response(conn, 401)
      assert response == %{"error" => "Error logging through google"}
    end

    test "logs the error when google returns an error", %{conn: conn} do
      Api.GoogleApi.ApiMock
      |> expect(:token_info, fn _token ->
        {:error, %{status_code: 500, body: "some error"}}
      end)

      assert capture_log(fn ->
               conn
               |> put_req_header("authorization", "Bearer 123")
               |> post(Routes.user_session_path(conn, :create_google))
             end) =~ "Error logging through google"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      refute get_session(conn, :user_token)
      response = json_response(conn, 200)
      assert response == %{"ok" => "Logged out successfully"}
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      refute get_session(conn, :user_token)
      response = json_response(conn, 200)
      assert response == %{"ok" => "Logged out successfully"}
    end
  end
end
