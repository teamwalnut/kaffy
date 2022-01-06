# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

config :api, Api.Repo,
  # ssl: true,
  username: System.get_env("DATABASE_USERNAME"),
  password: System.get_env("DATABASE_PASSWORD"),
  database: "api_prod",
  hostname: System.get_env("DATABASE_HOSTNAME"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "40")

config :api, AsyncJobs.Repo,
  # ssl: true,
  username: System.get_env("JOBS_DATABASE_USERNAME"),
  password: System.get_env("JOBS_DATABASE_PASSWORD"),
  database: System.get_env("JOBS_DATABASE_NAME"),
  hostname: System.get_env("JOBS_DATABASE_HOSTNAME"),
  pool_size: String.to_integer(System.fetch_env!("JOBS_DATABASE_POOL_SIZE"))

{:ok, hostname} = :inet.gethostname()

config :api,
  pubsub_server_conf:
    {Phoenix.PubSub,
     name: Api.PubSub,
     adapter: Phoenix.PubSub.Redis,
     host: System.get_env("REDIS_ENDPOINT"),
     port: String.to_integer(System.get_env("REDIS_PORT") || "6379"),
     node_name: hostname}

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :api, ApiWeb.Endpoint,
  url: [host: System.get_env("API_DOMAIN") || "api.teamwalnut.com", port: 443, scheme: "https"],
  server: true,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]],
    compress: true
  ],
  #   https: [
  #     port: 443,
  #     cipher_suite: :strong,
  #     keyfile: System.get_env("SSL_KEY_PATH"),
  #     certfile: System.get_env("SSL_CERT_PATH"),
  #     transport_options: [socket_opts: [:inet6]]
  #   ],
  secret_key_base: secret_key_base

config :api, Api.Mailer,
  adapter: Bamboo.MandrillAdapter,
  api_key: System.get_env("MANDRILL_API_KEY"),
  hackney_opts: [
    recv_timeout: :timer.minutes(1)
  ]

config :api, :metabase, jwt_key: System.get_env("METABASE_JWT_KEY")

#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
