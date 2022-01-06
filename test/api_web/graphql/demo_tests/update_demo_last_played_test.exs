defmodule ApiWeb.GraphQL.UpdateDemoLastPlayed do
  use ApiWeb.GraphQLCase

  load_gql(
    :update_demo_last_played,
    ApiWeb.Schema,
    "test/support/mutations/demos/UpdateDemoLastPlayed.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_demo
  ]

  describe "UpdateDemoLastPlayed" do
    test "it updates a demo last played field when user is unknown", %{
      demo: %{id: demo_id} = demo,
      public_storyline: %{id: storyline_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn nil, "demo_played", %{demo: ^demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_demo_last_played,
                 variables: %{"demoId" => demo.id}
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "updateDemoLastPlayed"])
      assert result["id"] != nil
      assert result["lastPlayed"] != nil
    end

    test "it updates a demo last played field when user is known", %{
      demo: %{id: demo_id} = demo,
      context: context,
      public_storyline: %{id: storyline_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn _user, "demo_played", %{demo: ^demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_demo_last_played,
                 variables: %{"demoId" => demo.id},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "updateDemoLastPlayed"])
      assert result["id"] != nil
      assert result["lastPlayed"] != nil
    end
  end
end
