defmodule ApiWeb.GraphQL.StorylineSettings do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/StorylineSettings.gql")

  setup [
    :register_and_log_in_user,
    :setup_company,
    :setup_member,
    :setup_public_storyline
  ]

  test "query nullable storyline settings", %{public_storyline: storyline, context: context} do
    query_gql(variables: %{"storylineId" => storyline.id}, context: context)
    |> match_snapshot(scrub: ["id"])
  end
end
