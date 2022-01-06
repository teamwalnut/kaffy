defmodule ApiWeb.SSOController do
  use ApiWeb, :controller

  require Logger
  alias Api.{Accounts, SSO}
  alias Api.SSO.CompanySSO
  alias ApiWeb.UserAuth

  action_fallback(ApiWeb.FallbackController)

  def get(conn, %{"provider" => "google"} = params) do
    redirect_uri = Routes.sso_url(ApiWeb.Endpoint, :callback)
    auto_close = params |> Map.get("autoClose", false)
    state = %{"autoClose" => auto_close} |> Jason.encode!()

    {:ok, auth_url} =
      WorkOS.SSO.get_authorization_url(%{
        provider: "GoogleOAuth",
        redirect_uri: redirect_uri,
        state: state
      })

    conn |> redirect(external: auth_url)
  end

  def get(conn, %{"email" => email} = params) do
    domain = email |> SSO.domain_from_email()
    redirect_uri = Routes.sso_url(ApiWeb.Endpoint, :callback)
    auto_close = params |> Map.get("autoClose", false)
    state = %{"autoClose" => auto_close} |> Jason.encode!()

    case Api.SSO.get_company_sso_by_domain(domain) do
      %CompanySSO{workos_conn_id: workos_conn_id} ->
        {:ok, auth_url} =
          WorkOS.SSO.get_authorization_url(%{
            connection: workos_conn_id,
            redirect_uri: redirect_uri,
            state: state
          })

        conn
        |> json(%{"result" => true, "redirect" => auth_url})

      resp ->
        Logger.info("Error logging in #{inspect(resp)}")

        conn
        |> json(%{"result" => false})
    end
  end

  def callback(conn, %{"code" => code}) do
    app_env = Application.fetch_env!(:api, :app_url)

    with {:work_os, {:ok, %{"profile" => %{"email" => email}}}} <-
           {:work_os, WorkOS.SSO.get_profile(code)},
         {:user, %Api.Accounts.User{} = user} <- {:user, Accounts.get_user_by_email(email)},
         {:user_locked?, false} <- {:user_locked?, user_locked?(user)} do
      ApiWeb.Analytics.identify(user)

      conn
      |> UserAuth.log_in_user(user, %{"remember_me" => true})
      |> redirect(external: app_env)
    else
      resp ->
        Logger.notice("Error logging in #{inspect(resp)}")

        conn
        |> redirect(external: app_env)
    end
  end

  defp user_locked?(%Api.Accounts.User{} = user) do
    with member <- Api.Companies.member_from_user(user.id),
         company <- Api.Companies.get_company!(member.company_id) do
      company.is_locked
    end
  end
end
