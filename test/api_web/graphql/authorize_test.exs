defmodule ApiWeb.GraphQL.AuthorizeTest do
  use ApiWeb.GraphQLCase

  load_gql(:authorize, ApiWeb.Schema, "test/support/queries/Authorize.gql")
  load_gql(:authorize_many, ApiWeb.Schema, "test/support/queries/AuthorizeMany.gql")

  setup [:register_and_log_in_member, :setup_public_storyline]

  describe "authorize" do
    test "storyline", %{public_storyline: storyline, context: context} do
      assert {:ok, res} =
               query_gql_by(:authorize,
                 variables: %{
                   "id" => storyline.id,
                   "resource" => "STORYLINE",
                   "relationship" => "VIEWER"
                 },
                 context: context
               )

      assert res.data["authorize"] == true
    end
  end

  @non_existing_id "51050db6-0e02-4514-8e7b-eb7d9cd8872a"
  describe "authorizeMany" do
    test "CurrentCompany (logged in)", %{public_storyline: storyline, context: context} do
      assert {:ok, res} =
               query_gql_by(:authorize_many,
                 variables: %{
                   "ids" => [storyline.id, @non_existing_id],
                   "resource" => "STORYLINE",
                   "relationship" => "VIEWER"
                 },
                 context: context
               )

      assert res.data["authorizeMany"] == [true, false]
    end
  end
end
