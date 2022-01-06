ExUnit.configure(formatters: [ExUnit.CLIFormatter, ExUnitNotifier])
Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)
Hammox.defmock(Api.S3Mock, for: Api.S3.API)
Hammox.defmock(ApiWeb.Analytics.ProviderMock, for: ApiWeb.Analytics.Provider.Behaviour)
# NOTE(Jaap): If you want to have detailed logging of for instance queries:
# - set the log level to :debug in test.exs:
#        config :logger, level: :debug
# - set the capture_log option below to false
ExUnit.start(capture_log: true)
