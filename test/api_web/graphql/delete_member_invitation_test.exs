defmodule ApiWeb.GraphQL.DeleteMemberInvitation do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :delete_member_invitation,
    ApiWeb.Schema,
    "test/support/mutations/DeleteMemberInvitation.gql"
  )

  setup [:register_and_log_in_member]

  setup %{member: member} do
    {:ok, %{member_invite: member_invite}} =
      Api.MemberInvite.invite_member("paz@walut.io", member)

    {:ok, member_invite: member_invite}
  end

  describe "DeleteMemberInvitation" do
    test "deletes a member invitation by id", %{
      context: context,
      member_invite: member_invite
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :delete_member_invitation,
                 variables: %{"memberInviteId" => member_invite.id},
                 context: context
               )

      no_errors!(query_data)

      get_in(query_data, [:data, "deleteMemberInvitation"])

      assert_raise Ecto.NoResultsError, fn ->
        Api.MemberInvite.get_member_invite!(member_invite.id)
      end
    end

    test "authorization", %{member_invite: member_invite, context: context} do
      TestAccess.assert_roles(
        &query_gql_by(
          :delete_member_invitation,
          variables: %{"memberInviteId" => member_invite.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: false, editor: false, company_admin: true}
      )
    end
  end
end
