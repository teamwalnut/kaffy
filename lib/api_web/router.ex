defmodule ApiWeb.Router do
  require Logger

  use ApiWeb, :router

  import ApiWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :graphql do
    plug(:fetch_session)
    plug(:fetch_current_user)
    plug(ApiWeb.Context)
  end

  pipeline :admin_only do
    plug(:fetch_current_user)
    plug(:requires_admin)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :requires_auth do
    plug(:require_authenticated_user)
  end

  forward("/ping", ApiWeb.Plugs.Liveness)

  use Kaffy.Routes, scope: "/admin", pipe_through: [:admin_only]

  scope "/" do
    pipe_through([
      :browser,
      :admin_only
    ])

    live_dashboard("/dashboard",
      metrics: ApiWeb.Telemetry,
      ecto_repos: [Api.Repo]
    )
  end

  scope "/graphql/graphiql" do
    pipe_through([
      :graphql,
      :admin_only
    ])

    forward(
      "/",
      Absinthe.Plug.GraphiQL,
      schema: ApiWeb.Schema
    )
  end

  scope "/graphql" do
    pipe_through(:graphql)

    forward("/", Absinthe.Plug,
      schema: ApiWeb.Schema,
      before_send: {ApiWeb.StableDemoParser, :absinthe_before_send},
      json_codec: Jason
    )
  end

  scope "/api", ApiWeb do
    pipe_through([:api])

    get("/assets", AssetController, :get)
    get("/login/sso", SSOController, :get)
    get("/login/sso/callback", SSOController, :callback)

    post("/login", UserSessionController, :create)

    delete("/logout", UserSessionController, :delete)

    # Keeping for backwards comp
    post("/login_with_google", UserSessionController, :create_google)
  end

  scope "/api", ApiWeb do
    pipe_through([
      :api,
      :require_authenticated_user
    ])

    post("/s3/request", S3Controller, :request)
    post("/assets/filter_existing", AssetController, :filter_existing)
    post("/assets/register", AssetController, :register)
  end

  # Display demo in embeded page for custom domains
  get("/demo/", ApiWeb.DemoController, :show)

  if Mix.env() == :dev do
    # View sent emails in development
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
