use Mix.Config

config :api,
  env: "test"

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :api, Api.Repo,
  username: "postgres",
  password: "postgres",
  database: "api_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  queue_target: 5000,
  pool: Ecto.Adapters.SQL.Sandbox

config :api, AsyncJobs.Repo,
  username: "postgres",
  password: "postgres",
  database: "jobs_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  queue_target: 5000,
  pool: Ecto.Adapters.SQL.Sandbox

config :api,
  pubsub_server_conf: {Phoenix.PubSub, name: Api.PubSub}

config :phoenix, :plug_init_mode, :runtime

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :api, ApiWeb.Endpoint,
  url: [host: "api.walnut.example.com", scheme: "https"],
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger,
  level: :notice,
  backends: [:console]

config :api, :app_url, "https://app.testwalnut.com"
config :api, ld_sdk_key: "sdk-930972fd-6156-40d4-9335-dc2fbc64efa4"

config :api,
  s3_api: Api.S3Mock,
  file_store: Api.FileStore.Mock,
  analytics: ApiWeb.Analytics.ProviderMock,
  engagement: ApiWeb.Engagement.ProviderMock,
  features_flags: ApiWeb.FeaturesFlags.Provider.Stub

config :api, Api.Mailer, adapter: Bamboo.TestAdapter
config :api, Api.GoogleApi, api: Api.GoogleApi.ApiMock

config :workos,
  client_id: "client_id",
  api_key: "testKey",
  adapter: Tesla.Mock

config :tesla, Api.S3.TeslaMint, adapter: Tesla.Mock

config :sentry,
  tags: %{
    env: "test"
  }

config :segment,
  is_enabled: false

config :api, :metabase, jwt_key: "test"

config :api, Oban, queues: false, plugins: false
