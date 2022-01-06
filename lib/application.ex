defmodule ApiApplication do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias ApiWeb.FeaturesFlags.Provider.Launchdarkly

  def start(_type, _args) do
    attach_telemetry()
    Launchdarkly.start_instance()

    children = [
      {Absinthe.Schema, ApiWeb.Schema},
      # Start the Ecto repositories
      Api.Repo,
      AsyncJobs.Repo,
      # Start the Telemetry supervisor
      ApiWeb.Telemetry,
      # Start the PubSub system
      Application.get_env(:api, :pubsub_server_conf),
      {SpandexDatadog.ApiServer, spandex_datadog_options()},
      ApiWeb.Presence,
      # Start the Endpoint (http/https)
      ApiWeb.Endpoint,
      # Start a worker by calling: Api.Worker.start_link(arg)
      # {Api.Worker, arg}
      {Oban, Application.fetch_env!(:api, Oban)}
    ]

    children =
      if Application.get_env(:segment, :is_enabled) do
        children ++ [{Segment, segment_config()}]
      else
        children
      end

    children =
      if Application.get_env(:api, :env) == "test" do
        children ++ [Api.FixtureSequence]
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Api.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp segment_config do
    [Application.fetch_env!(:segment, :write_key)]
  end

  defp attach_telemetry do
    :ok =
      :telemetry.attach(
        "logger-json-ecto",
        [:api, :repo, :query],
        &LoggerJSON.Ecto.telemetry_logging_handler/4,
        :debug
      )

    :ok =
      :telemetry.attach(
        "spandex-query-tracer-api",
        [:api, :repo, :query],
        &SpandexEcto.TelemetryAdapter.handle_event/4,
        nil
      )

    SpandexPhoenix.Telemetry.install()
  end

  defp spandex_datadog_options do
    config = Application.get_all_env(:spandex_datadog)
    config_host = config[:host]
    config_port = config[:port]
    config_batch_size = config[:batch_size]
    config_sync_threshold = config[:sync_threshold]
    config_http = config[:http]

    spandex_datadog_options(
      config_host,
      config_port,
      config_batch_size,
      config_sync_threshold,
      config_http
    )
  end

  defp spandex_datadog_options(
         config_host,
         config_port,
         config_batch_size,
         config_sync_threshold,
         config_http
       ) do
    [
      host: config_host || "localhost",
      port: config_port || 8126,
      batch_size: config_batch_size || 10,
      sync_threshold: config_sync_threshold || 100,
      http: config_http || HTTPoison
    ]
  end
end
