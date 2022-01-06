defmodule Api.SentryEventFilter do
  @moduledoc """
  See https://docs.sentry.io/platforms/elixir/#filtering-events for documentation
  """
  require Logger
  @behaviour Sentry.EventFilter

  def exclude_exception?(%Phoenix.Router.NoRouteError{} = err, :plug) do
    Logger.warn(inspect(err))
    true
  end

  def exclude_exception?(_exception, _source), do: false
end
