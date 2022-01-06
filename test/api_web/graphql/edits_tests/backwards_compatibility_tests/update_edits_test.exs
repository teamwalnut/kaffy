defmodule ApiWeb.GraphQL.BackwardsCompatibilityTests.UpdateEditsTest do
  use ApiWeb.GraphQLCase

  load_gql(
    :add_edits_bc,
    ApiWeb.Schema,
    "test/api_web/graphql/edits_tests/backwards_compatibility_tests/AddEdits.gql"
  )

  load_gql(
    :update_edits_bc,
    ApiWeb.Schema,
    "test/api_web/graphql/edits_tests/backwards_compatibility_tests/UpdateEditsInScreen.gql"
  )

  setup [:register_and_log_in_member]

  describe "updateEditsInScreen" do
    test "it should correctly update the edits", %{
      context: %{current_user: %{email: user_email}} = context,
      member: member
    } do
      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      screen2 =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      {:ok, query_data} =
        query_gql_by(
          :add_edits_bc,
          variables: %{"screenId" => screen.id},
          context: context
        )

      no_errors!(query_data)
      edits = get_in(query_data, [:data, "addEditsToScreen"])
      link_edit = edits |> Enum.find(&(&1["kind"] == "LINK"))

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 1, fn ^user_email, type, _attrs ->
        if type |> String.ends_with?("_edit_updated"), do: :ok, else: :error
      end)

      link_edit =
        link_edit
        |> update_in(["linkEditProps"], fn _ -> %{"target_screen_id" => screen2.id} end)

      {:ok, query_data} =
        query_gql_by(
          :update_edits_bc,
          variables: %{
            "screenId" => screen.id,
            "edits" => [
              link_edit
            ]
          },
          context: context
        )

      no_errors!(query_data)
      results = get_in(query_data, [:data, "updateEditsInScreen"])

      assert results == [
               %{
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => "i.css.like",
                 "id" => results |> Enum.at(0) |> Map.get("id"),
                 "kind" => "LINK",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "linkEditProps" => %{
                   "targetScreen" => %{"id" => screen2.id}
                 }
               }
             ]
    end
  end
end
