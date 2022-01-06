# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :api, Api.Repo,
  priv: "priv/repo",
  loggers: [{Ecto.LogEntry, :log, []}],
  log: false,
  migration_timestamps: [type: :utc_datetime_usec],
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [column: :id, type: :binary_id]

config :api, AsyncJobs.Repo,
  priv: "priv/async_jobs",
  loggers: [{Ecto.LogEntry, :log, []}],
  log: false,
  migration_timestamps: [type: :utc_datetime_usec],
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [column: :id, type: :binary_id]

config :api,
  analytics: ApiWeb.Analytics.Provider,
  engagement: ApiWeb.Engagement.Provider,
  features_flags: ApiWeb.FeaturesFlags.Provider,
  ecto_repos: [Api.Repo, AsyncJobs.Repo],
  generators: [binary_id: true],
  migration: true,
  min_pass_length: 11

config :cors_plug,
  headers: [
    "Authorization",
    "Content-Type",
    "Accept",
    "Origin",
    "User-Agent",
    "DNT",
    "Cache-Control",
    "X-Mx-ReqToken",
    "Keep-Alive",
    "X-Requested-With",
    "If-Modified-Since",
    "X-CSRF-Token",
    "x-datadog-origin",
    "x-datadog-sampled",
    "x-datadog-trace-id",
    "x-datadog-parent-id",
    "x-datadog-sampling-priority",
    "Timing-Allow-Origin"
  ]

config :api, :session,
  store: :cookie,
  key: "_api_key",
  signing_salt: "+QXFqlGa",
  secure: true,
  http_only: true,
  same_site: "None",
  domain: ".walnut.example.com"

config :sentry,
  dsn: "https://665e6468c05b4072b5aefc01e842d4d0@o482146.ingest.sentry.io/5531885",
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  environment_name: Mix.env(),
  included_environments: [:prod],
  filter: Api.SentryEventFilter

# Configures the endpoint
config :api, ApiWeb.Endpoint,
  secret_key_base: "Rp/bvr787TqB2/TW2njEKAkbjINhUJwSJi3ykRL8ZUD1y+EN0mZg1IYsllqJV8xP",
  render_errors: [view: ApiWeb.ErrorView, accepts: ~w(json)],
  live_view: [signing_salt: "MQGQkLsC"],
  pubsub_server: Api.PubSub

config :kaffy,
  admin_title: "Walnut - Admin",
  resources: &Api.Kaffy.Config.create_resources/1,
  otp_app: :api,
  ecto_repo: Api.Repo,
  router: ApiWeb.Router

config :mojito,
  pool_opts: [
    size: 100,
    pools: 50,
    max_overflow: 50
  ],
  timeout: 50_000

config :logger_json, :backend,
  json_encoder: Jason,
  metadata: :all

config :logger,
  backends: [LoggerJSON, Sentry.LoggerBackend],
  level: :debug,
  utc_log: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$dateT$time [$level]$levelpad $metadata $message\n",
  level: :debug,
  metadata: [
    :user_id,
    :user_mail,
    :fetch_asset_name,
    :fetch_asset_result,
    :request_id,
    :span_id,
    :trace_id
  ]

config :ex_aws,
  region: "us-west-2",
  json_codec: Jason,
  http_client: Api.ExAwsHttpClient,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

config :api, :s3_api, Api.S3
config :api, file_store: Api.FileStore.S3

config :api, Api.Tracer,
  service: :api,
  adapter: SpandexDatadog.Adapter,
  disabled?: true,
  tags: [
    version: "dev"
  ]

config :spandex_ecto, SpandexEcto.EctoLogger,
  service: :ecto,
  tracer: Api.Tracer

config :spandex_phoenix, tracer: Api.Tracer

config :spandex_datadog,
  host: "localhost",
  port: 8126,
  batch_size: 10,
  sync_threshold: 100,
  http: HTTPoison

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :phoenix, :format_encoders, json: Jason
config :absinthe, schema: ApiWeb.Schema
config :api, Api.GoogleApi, api: Api.GoogleApi.Api

config :api, Oban,
  repo: AsyncJobs.Repo,
  plugins: [
    Oban.Plugins.Pruner
  ],
  queues: [default: 10]

config :segment,
  is_enabled: true

config :mime, :types, %{
  "application/xml" => ["xml"]
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
