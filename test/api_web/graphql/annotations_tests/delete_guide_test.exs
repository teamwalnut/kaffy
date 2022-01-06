defmodule ApiWeb.GraphQL.DeleteGuide do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :delete_guide,
    ApiWeb.Schema,
    "test/support/mutations/annotations/DeleteGuide.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_guide
  ]

  describe "DeleteGuide" do
    test "it deletes a guide", %{
      context: %{current_user: %{email: user_email}} = context,
      guide: %{id: guide_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email, "guide_deleted", %{guide: ^guide_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :delete_guide,
                 variables: %{"id" => guide_id},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "deleteGuide"])

      refute is_nil(result["id"])
    end

    test "authorization", %{context: context, guide: %{id: guide_id}} do
      TestAccess.assert_roles(
        &query_gql_by(
          :delete_guide,
          variables: %{"id" => guide_id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
