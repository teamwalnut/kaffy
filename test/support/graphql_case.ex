defmodule ApiWeb.GraphQLCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      use Api.DataCase
      use Wormwood.GQLCase
      import ExUnit.CaptureLog
      import ApiWeb.GraphQLCase
      use Api.Fixtures
      setup :verify_on_exit!
    end
  end

  setup _tags do
    # reset sequence counts each run, so the generated names are always deterministic
    Api.FixtureSequence.reset()
    Hammox.stub_with(ApiWeb.Analytics.ProviderMock, ApiWeb.Analytics.Provider.Stub)
    Hammox.stub_with(ApiWeb.Engagement.ProviderMock, ApiWeb.Engagement.Provider)
    :ok
  end

  # Snapshy doesn't allow multiple variations of snapshots in a test
  # this fixes that, in a hacky way that works perfectly fine
  # Snapshy is a very simple library that we can also vendor of it's
  # necessary, but this works for now
  #
  # Examples:
  #
  #   query_gql(...)
  #   |> match_snapshot()
  #
  # If you wnat to allow more than one snapshots per test:
  #
  #   query_gql(...)
  #   |> match_snapshot(variation: "my_variation")
  #
  # Also scrubbing build-in:
  #
  #   query_gql(...)
  #   |> match_snapshot(variation: "my_variation", scrub: "id")

  defmacro match_snapshot(value, opts \\ []) do
    variation =
      case opts[:variation] do
        nil -> ""
        variation -> "_" <> variation
      end

    quote do
      Snapshy.match(
        scrub(unquote(value), unquote(opts[:scrub])),
        case(unquote(Macro.escape(__CALLER__))) do
          %Macro.Env{function: {function_name, other}, file: file} ->
            %Macro.Env{function: {:"#{function_name}#{unquote(variation)}", other}, file: file}
        end
      )
    end
  end

  @doc """
  Setup helper that creates a user and provides a context with it:

  `setup :register_and_log_in_user`

  You should use `register_and_log_in_member/1`, this will be deprecated
  """
  def register_and_log_in_user(_args) do
    user = Api.AccountsFixtures.user_fixture()
    %{context: %{:current_user => user}, user: user}
  end

  @doc """
  Setup helper that creates a company, user, and member and provides a context with it:

  `setup :register_and_log_in_member`
  """
  def register_and_log_in_member(_args \\ %{}) do
    user = Api.AccountsFixtures.user_fixture()
    company = Api.CompaniesFixtures.company_fixture()
    {:ok, member} = Api.Companies.add_member(user.id, company, %{role: :company_admin})
    member = member |> Api.Repo.preload([:user, :company])

    %{
      context: %{:current_user => user, current_member: member},
      user: user,
      member: member,
      company: company
    }
  end

  def map_flow_to_gql_struct(flow) do
    %{
      "id" => flow.id,
      "is_default" => flow.is_default,
      "name" => flow.name,
      "position" => flow.position,
      "screens" => flow.screens
    }
  end

  def no_errors!(query_data) do
    errors = get_in(query_data, [:errors])

    if is_nil(errors) do
      true
    else
      throw(errors)
    end
  end

  def unauthorized_error(query_data) do
    errors = get_in(query_data, [:errors])

    Enum.at(errors, 0)[:code] == :unauthorized
  end

  @doc """
  scrub certain fields in a data structure, this is mainly used for snapshot testing
  """
  def scrub(m, nil), do: m
  def scrub(m, []), do: m
  def scrub(m, [token | tokens]) when is_list(tokens), do: m |> scrub(token) |> scrub(tokens)
  def scrub({token, _val}, token), do: {token, "scrubbed"}

  def scrub(tuple, token) when is_tuple(tuple),
    do: List.to_tuple(scrub(Tuple.to_list(tuple), token))

  def scrub([el | rest], token), do: [scrub(el, token) | scrub(rest, token)]

  def scrub(%{__struct__: _} = m, token), do: scrub(Map.from_struct(m), token)

  def scrub(%{} = m, token),
    do: m |> Enum.map(fn {key, val} -> scrub({key, val}, token) end) |> Enum.into(%{})

  def scrub(m, _), do: m
end
