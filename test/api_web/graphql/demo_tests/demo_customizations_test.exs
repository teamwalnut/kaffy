defmodule ApiWeb.GraphQL.DemoCustomizationsTest do
  use ApiWeb.GraphQLCase

  load_gql(
    :create_or_update_variable,
    ApiWeb.Schema,
    "test/support/mutations/CreateOrUpdateVariable.gql"
  )

  load_gql(:variables, ApiWeb.Schema, "test/support/queries/Variables.gql")

  describe "DemoCustomizations" do
    setup [:register_and_log_in_member, :setup_public_storyline]

    test "it should be able to create variable", %{public_storyline: storyline, context: context} do
      query_gql_by(:create_or_update_variable,
        variables: %{
          "storylineId" => storyline.id,
          "name" => "name",
          "description" => "description",
          "defaultValue" => "defaultValue",
          "kind" => "TEXT"
        },
        context: context
      )
      |> match_snapshot(scrub: ["id"])
    end

    test "it should be list variables", %{public_storyline: storyline, context: context} do
      query_gql_by(:create_or_update_variable,
        variables: %{
          "storylineId" => storyline.id,
          "name" => "name",
          "description" => "description",
          "defaultValue" => "defaultValue",
          "kind" => "TEXT"
        },
        context: context
      )

      query_gql_by(:create_or_update_variable,
        variables: %{
          "storylineId" => storyline.id,
          "name" => "image",
          "description" => "description",
          "defaultValue" => "defaultValue",
          "kind" => "IMAGE"
        },
        context: context
      )

      query_gql_by(:variables,
        variables: %{
          "storylineId" => storyline.id
        },
        context: context
      )
      |> match_snapshot(scrub: ["id"])
    end
  end
end
