defmodule ApiWeb.Schema.FeaturesFlagsTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  import ApiWeb.FeaturesFlags
  alias ApiWeb.FeaturesFlags.Provider.Launchdarkly

  @doc """
  The level of logging to be used.

  When in doubt, use `:error` as the default.

  Follows: https://www.ietf.org/rfc/rfc5424.txt
  """
  enum :log_level do
    value(:emergency, description: "Emergency log level")
    value(:alert, description: "Alert log level")
    value(:critical, description: "Critical log level")
    value(:error, description: "Error log level")
    value(:warning, description: "Warning log level")
    value(:notice, description: "Notice log level")
    value(:info, description: "Info log level")
    value(:debug, description: "Debug log level")
  end

  @desc "FeaturesFlags of the current_user"
  object :features_flags do
    graphql_fields()
  end

  object :features_flag_queries do
    field :features_flags, :features_flags do
      resolve(fn
        _parent, _args, %{context: %{current_user: current_user}} ->
          :ok = Launchdarkly.identify(current_user)
          features_flags = current_user |> Launchdarkly.get_features_flags()

          {:ok, features_flags}

        _, _, _ ->
          {:ok, nil}
      end)
    end
  end
end
