defmodule ApiWeb.GraphQL.RepositionAnnotation do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :reposition_annotation,
    ApiWeb.Schema,
    "test/support/mutations/annotations/RepositionAnnotation.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide,
    :setup_multiple_annotations
  ]

  describe "RepositionAnnotation" do
    test "it repositions an annotation to a new position", %{
      annotations: annotations,
      context: context
    } do
      annotation = List.first(annotations)

      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_annotation,
                 variables: %{
                   "id" => annotation.id,
                   "step" => 2
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "repositionAnnotation"])
      assert result["id"] == annotation.id
      assert result["step"] == 2
    end

    test "it fails to reposition an annotation to an invalid (OFB) position", %{
      annotations: annotations,
      context: context
    } do
      annotation = List.first(annotations)

      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_annotation,
                 variables: %{
                   "id" => annotation.id,
                   "step" => 4
                 },
                 context: context
               )

      error = get_in(query_data, [:errors]) |> Enum.at(0)
      assert error[:message] == "The new step position is out of bounds"
    end

    test "it fails to reposition an annotation to an invalid (negative) position", %{
      annotations: annotations,
      context: context
    } do
      annotation = List.first(annotations)

      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_annotation,
                 variables: %{
                   "id" => annotation.id,
                   "step" => -1
                 },
                 context: context
               )

      error = get_in(query_data, [:errors]) |> Enum.at(0)
      assert error[:message] == "Something went wrong"
    end

    test "authorization", %{
      annotations: annotations,
      context: context
    } do
      annotation = List.first(annotations)

      TestAccess.assert_roles(
        &query_gql_by(
          :reposition_annotation,
          variables: %{"id" => annotation.id, "step" => 2},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
