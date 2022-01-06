defmodule ApiWeb.GraphQL.UpdateMemberRole do
  use ApiWeb.GraphQLCase

  set_gql(
    :update_member_role,
    ApiWeb.Schema,
    Wormwood.GQLLoader.load_file!("test/support/mutations/UpdateMemberRole.gql")
  )

  setup [:register_and_log_in_user, :setup_company, :setup_member]

  setup %{context: %{current_user: _current_user}, company: company} do
    new_user = Api.AccountsFixtures.user_fixture()

    {:ok, member: new_member} =
      Api.CompaniesFixtures.setup_member(%{user: new_user, company: company})

    {:ok, member_to_update: new_member}
  end

  describe "UpdateMemberRole" do
    test "update member role", %{
      context: context,
      member_to_update: member_to_update
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :update_member_role,
                 variables: %{"memberId" => member_to_update.id, "role" => "EDITOR"},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "updateMemberRole"])

      assert result["id"] == member_to_update.id
      assert result["role"] == "EDITOR"
    end
  end
end
