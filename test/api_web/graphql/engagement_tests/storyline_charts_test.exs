defmodule ApiWeb.GraphQL.StorylineCharts do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/StorylineCharts.gql")

  setup [
    :register_and_log_in_member,
    :setup_public_storyline
  ]

  describe "storyline charts" do
    test "lists all charts for a storyline", %{
      context: context,
      user: _user,
      public_storyline: %{id: storyline_id} = _storyline
    } do
      assert {:ok, query_data} =
               query_gql(
                 variables: %{"storylineId" => storyline_id},
                 context: context
               )

      no_errors!(query_data)

      assert %{
               data: %{
                 "storylineCharts" => [
                   %{"name" => "demos_visits", "src" => _jwt_tokenized_url}
                 ]
               }
             } = query_data
    end
  end
end
