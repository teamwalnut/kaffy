defmodule ApiWeb.UserSessionController do
  use ApiWeb, :controller

  require Logger

  alias Api.{Accounts, SSO}
  alias ApiWeb.UserAuth

  action_fallback(ApiWeb.FallbackController)

  # Note(Danni): keeping for backwards comp, all new request should go to sso_controller
  def create_google(conn, _params) do
    ["Bearer " <> token] = get_req_header(conn, "authorization")

    with {:token_info, {:ok, %{"email" => email}}} <-
           {:token_info, Api.GoogleApi.token_info(token)},
         nil <- SSO.domain_from_email(email) |> SSO.get_company_sso_by_domain(),
         {:user, %Api.Accounts.User{} = user} <- {:user, Accounts.get_user_by_email(email)},
         false <- user_locked?(user) do
      ApiWeb.Analytics.identify(user)

      conn
      |> UserAuth.log_in_user(user, %{"remember_me" => true})
      |> render("create.json", %{ok: "Logged in successfully"})
    else
      resp ->
        Logger.notice("Error logging through google #{inspect(%{resp: resp})}")

        conn
        |> put_status(401)
        |> render("error.json", error_message: "Error logging through google")
    end
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    domain = email |> SSO.domain_from_email()

    with nil <- SSO.get_company_sso_by_domain(domain),
         user <- Accounts.get_user_by_email_and_password(email, password),
         false <- user_locked?(user) do
      ApiWeb.Analytics.identify(user)

      conn
      |> UserAuth.log_in_user(user, user_params)
      |> render("create.json", %{ok: "Logged in successfully"})
    else
      _ ->
        Logger.warn("Incorrect username/password", %{"email" => email})

        conn
        |> put_status(401)
        |> render("error.json", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> render("logout.json", %{ok: "Logged out successfully"})
  end

  defp user_locked?(%Api.Accounts.User{} = user) do
    with member <- Api.Companies.member_from_user(user.id),
         company <- Api.Companies.get_company!(member.company_id) do
      company.is_locked
    end
  end

  defp user_locked?(nil) do
    true
  end
end
