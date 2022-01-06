defmodule ApiWeb.GraphQL.DeleteMember do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :delete_member,
    ApiWeb.Schema,
    "test/support/mutations/DeleteMember.gql"
  )

  setup [:register_and_log_in_member]

  setup %{context: %{current_user: _current_user}, company: company} do
    new_user = Api.AccountsFixtures.user_fixture()

    {:ok, member: new_member} =
      Api.CompaniesFixtures.setup_member(%{user: new_user, company: company})

    {:ok, member_to_delete: new_member}
  end

  describe "DeleteMember" do
    test "deletes a member invitation by id", %{
      context: context,
      member_to_delete: member_to_delete
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :delete_member,
                 variables: %{"memberId" => member_to_delete.id},
                 context: context
               )

      no_errors!(query_data)

      get_in(query_data, [:data, "deleteMember"])

      assert_raise Ecto.NoResultsError, fn ->
        Api.Companies.get_member!(member_to_delete.id)
      end
    end

    test "authorization", %{context: context, member_to_delete: member_to_delete} do
      TestAccess.assert_roles(
        &query_gql_by(
          :delete_member,
          variables: %{"memberId" => member_to_delete.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: false, editor: false, company_admin: true}
      )
    end
  end
end
