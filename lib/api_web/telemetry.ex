defmodule ApiWeb.Telemetry do
  @moduledoc false
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @env Application.compile_env!(:api, :env)
  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      # {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()},
      {TelemetryMetricsStatsd,
       [
         metrics: metrics(),
         prefix: "api",
         global_tags: [env: @env],
         formatter: :datadog
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    if Application.get_env(:api, :env) == "prod" do
      [
        # Phoenix Metrics
        summary("phoenix.router_dispatch.stop.duration",
          tags: [:route],
          unit: {:native, :millisecond}
        ),
        summary("phoenix.endpoint.stop.duration",
          tag_values: &phoenix_enpoint_stop_tag_values/1,
          tags: [:status, :request_path],
          unit: {:native, :millisecond}
        ),

        # Database Metrics
        summary("api.repo.query.decode_time",
          unit: {:native, :millisecond},
          tags: [:source]
        ),
        summary("api.repo.query.query_time",
          unit: {:native, :millisecond},
          tags: [:source]
        ),
        summary("api.repo.query.queue_time",
          unit: {:native, :millisecond},
          tags: [:source]
        ),
        distribution("api.repo.query.idle_time", unit: {:native, :millisecond}),
        # distribution("api.repo.query.total_time", unit: {:native, :millisecond}),
        counter(
          "api.repo.query.count",
          tags: [:source, :command]
        ),
        summary(
          "api.repo.query.total_time",
          unit: {:native, :millisecond},
          tags: [:source, :command]
        ),

        # VM Metrics
        summary("vm.memory.total", unit: {:byte, :kilobyte}),
        summary("vm.total_run_queue_lengths.total"),
        summary("vm.total_run_queue_lengths.cpu"),
        summary("vm.total_run_queue_lengths.io"),

        # Absinthe Metrics
        summary("absinthe.execute.operation.stop.duration", unit: {:native, :millisecond}),
        summary("absinthe.subscription.publish.stop.duration", unit: {:native, :millisecond}),
        summary("absinthe.middleware.batch.stop.duration", unit: {:native, :millisecond}),
        summary("absinthe.resolve.field.stop.duration",
          tag_values: &absinthe_resolve_field_tag_values/1,
          tags: [:path],
          unit: {:native, :millisecond}
        ),

        # Tesla Metrics
        summary("tesla.request.stop.duration",
          tag_values: &tesla_resolve_tag_values/1,
          tags: [:method, :query, :url, :status],
          unit: {:native, :millisecond}
        ),

        # Mojito Metrics
        summary("mojito.request.stop.duration",
          tags: [:host, :port, :path, :method],
          unit: {:native, :millisecond}
        )
      ]
    else
      []
    end
  end

  # defp periodic_measurements do
  #   [
  #     # A module, function and arguments to be invoked periodically.
  #     # This function must call :telemetry.execute/3 and a metric must be added above.
  #     # {ApiWeb, :count_users, []}
  #   ]
  # end

  defp absinthe_resolve_field_tag_values(%{resolution: resolution}) do
    %{
      path:
        resolution |> Absinthe.Resolution.path() |> Enum.filter(&is_binary/1) |> Enum.join(".")
    }
  end

  defp phoenix_enpoint_stop_tag_values(%{conn: conn}) do
    %{
      request_path: conn.request_path,
      status: conn.status
    }
  end

  defp tesla_resolve_tag_values(%{env: env}) do
    %{
      method: env.method,
      query: env.query,
      url: env.url,
      status: env.status
    }
  end
end
