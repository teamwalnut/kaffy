defmodule ApiWeb.FeaturesFlags do
  @moduledoc """
  This module wraps currently the LaunchDarkly API, returns a list of features flags
  from it, using our Api.Accounts.User.

  Also provides the identify functionality of LaunchDarkly so we will sync our users with
  it.

  To add a new field, add it here so we will automatically get it in the GraphQL API
  """
  @flags [
    {"richer-guides", :boolean},
    {"smart-objects", :boolean},
    {"storyline-hierarchy", :boolean},
    {"auto-link", :boolean},
    {"bindings", :boolean},
    {"delay-link", :boolean},
    {"engagement", :boolean},
    {"link-url", :boolean},
    {"multiple-resolutions", :boolean},
    {"offline-demos-poc", :boolean},
    {"log-level", :log_level},
    {"bounce-rate", :boolean},
    {"show-compliance-modal", :boolean},
    {"new-guides-ux", :boolean},
    {"editor-sidebar-settings", :boolean},
    {"additional-sidebar-settings", :boolean},
    {"bulk-actions", :boolean},
    {"demo-controls", :boolean},
    {"help-center", :boolean},
    {"account-global-settings", :boolean},
    {"roles-and-permissions", :boolean},
    {"additional-guides-settings", :boolean},
    {"guides-fpp", :boolean},
    {"additional-token", :boolean},
    {"annotation-settings", :boolean},
    {"async-find-and-replace-job", :boolean},
    {"multiple-cta", :boolean}
  ]

  defp to_snake_atom(str) do
    String.replace(str, "-", "_") |> String.to_atom()
  end

  defmacro graphql_fields do
    for {f, t} <- @flags do
      quote do
        field(unquote(to_snake_atom(f)), unquote(t))
      end
    end
  end

  # runtime access to the feature flags
  def flags, do: @flags

  defmodule Provider do
    def make do
      Application.get_env(:api, :features_flags)
    end

    defmodule Behaviour do
      @moduledoc false
      @callback all_flags_state(user :: :ldclient_user.user()) ::
                  :ldclient_eval.feature_flags_state()
      @callback identify(user :: :ldclient_user.user()) :: :ok
      @callback start_instance(sdk_key :: String.t(), tag_or_options :: atom() | map()) :: :ok
    end

    defmodule Stub do
      use Agent
      @moduledoc false
      @behaviour Behaviour

      def all_flags_state(_user) do
        %{
          flag_values: %{
            "auto-link" => true,
            "multiple-resolutions" => false,
            "log-level" => "WARNING"
          }
        }
      end

      def identify(_user), do: :ok

      def start_instance(sdk_key, tag_or_options) do
        # note(itay): Using an agent to store the variables passed to start_instance
        # so later on in the tests I could easily retrieve the state and check that
        # it is as expected.
        Agent.start_link(fn -> {sdk_key, tag_or_options} end, name: __MODULE__)
        :ok
      end
    end

    @behaviour Behaviour
    def all_flags_state(user) do
      user
      |> :ldclient.all_flags_state()
    end

    def identify(user) do
      user
      |> :ldclient.identify()
    end

    def start_instance(sdk_key, tag_or_options) do
      :ldclient.start_instance(sdk_key, tag_or_options)
    end

    defmodule Launchdarkly do
      @moduledoc false
      alias Api.Repo

      def get_features_flags(user) do
        %{flag_values: features_flags} =
          user
          |> to_launchdarkly_user()
          |> Provider.make().all_flags_state()

        features_flags
        |> from_launchdarkly_features_flags()
      end

      def identify(user) do
        user
        |> to_launchdarkly_user()
        |> Provider.make().identify()
      end

      def start_instance do
        sdk_key = String.to_charlist(Application.get_env(:api, :ld_sdk_key))

        Provider.make().start_instance(
          sdk_key,
          %{
            stream: true
          }
        )
      end

      defp to_launchdarkly_user(user) do
        user = user |> Repo.preload(:companies)

        %{
          key: user.email,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          custom: %{
            company_ids: user.companies |> Enum.map(& &1.id)
          }
        }
      end

      defp from_launchdarkly_features_flags(features_flags) do
        features_flags
        |> Map.take(ApiWeb.FeaturesFlags.flags() |> Enum.map(fn {flag, _} -> flag end))
        |> Map.to_list()
        |> Enum.map(fn {k, v} ->
          {
            String.replace(k, "-", "_") |> String.to_existing_atom(),
            v
          }
        end)
        |> Enum.map(fn
          {:log_level, v} -> {:log_level, v |> String.downcase() |> String.to_existing_atom()}
          kv -> kv
        end)
        |> Map.new()
      end
    end
  end
end
