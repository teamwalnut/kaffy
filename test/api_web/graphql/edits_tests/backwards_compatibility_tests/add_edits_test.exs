defmodule ApiWeb.GraphQL.BackwardsCompatibilityTests.AddEditsTest do
  use ApiWeb.GraphQLCase

  load_gql(
    :add_edits_bc,
    ApiWeb.Schema,
    "test/api_web/graphql/edits_tests/backwards_compatibility_tests/AddEdits.gql"
  )

  load_gql(
    :add_edits_bc_writenew_readold,
    ApiWeb.Schema,
    "test/api_web/graphql/edits_tests/backwards_compatibility_tests/AddEdits-WriteNew-ReadOld.gql"
  )

  setup [:verify_on_exit!, :register_and_log_in_member]

  describe "addEditsToScreen" do
    test "it should append edits correctly depending on their type", %{
      context: %{current_user: %{email: user_email}} = context,
      member: member
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 1, fn ^user_email, type, _attrs ->
        if type |> String.ends_with?("edit_created"), do: :ok, else: :error
      end)

      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      result =
        query_gql_by(:add_edits_bc, variables: %{"screenId" => screen.id}, context: context)

      assert {:ok, query_data} = result
      no_errors!(query_data)

      results = get_in(query_data, [:data, "addEditsToScreen"])

      assert results == [
               %{
                 "domSelector" => nil,
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => "i.css.like",
                 "id" => results |> Enum.at(0) |> Map.get("id"),
                 "kind" => "LINK",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "linkEditProps" => %{
                   "targetScreen" => %{"id" => screen.id}
                 }
               }
             ]
    end

    test "it should be able to write using the new API and read using the old API", %{
      context: %{current_user: %{email: user_email}} = context,
      member: member
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 1, fn ^user_email, type, _attrs ->
        if type |> String.ends_with?("edit_created"), do: :ok, else: :error
      end)

      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      result =
        query_gql_by(:add_edits_bc_writenew_readold,
          variables: %{"screenId" => screen.id},
          context: context
        )

      assert {:ok, query_data} = result
      no_errors!(query_data)

      results = get_in(query_data, [:data, "addEditsToScreen"])

      assert results == [
               %{
                 "domSelector" => nil,
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => "i.css.like",
                 "id" => results |> Enum.at(0) |> Map.get("id"),
                 "kind" => "LINK",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "linkEditProps" => %{
                   "targetScreen" => %{"id" => screen.id}
                 }
               }
             ]
    end
  end
end
