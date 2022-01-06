defmodule ApiWeb.GraphQL.DeleteAnnotation do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :delete_annotation,
    ApiWeb.Schema,
    "test/support/mutations/annotations/DeleteAnnotation.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide,
    :setup_point_annotation
  ]

  describe "DeleteAnnotation" do
    test "it deletes an annotation", %{
      context: %{current_user: %{email: user_email}} = context,
      annotation: %{id: annotation_id},
      guide: %{id: guide_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "annotation_deleted",
                           %{guide: ^guide_id, annotation: ^annotation_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :delete_annotation,
                 variables: %{
                   "id" => annotation_id
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "deleteAnnotation"])

      refute is_nil(result["id"])
    end

    test "authorization", %{context: context, annotation: %{id: annotation_id}} do
      TestAccess.assert_roles(
        &query_gql_by(
          :delete_annotation,
          variables: %{"id" => annotation_id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
