defmodule ApiWeb.GraphQL.InviteMember do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :bulk_invite_members,
    ApiWeb.Schema,
    "test/support/mutations/InviteMembers.gql"
  )

  load_gql(
    :invite_member,
    ApiWeb.Schema,
    "test/support/mutations/InviteMember.gql"
  )

  setup [:register_and_log_in_member, :setup_company]

  describe "InviteMember" do
    test "it invites a member to a company with default role: admin", %{
      context: context
    } do
      email = "paz@walnut.io"

      assert {:ok, query_data} =
               query_gql_by(
                 :invite_member,
                 variables: %{"email" => email},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "inviteMember"])

      assert result["id"] != nil
      assert result["email"] == email
      assert result["role"] == "COMPANY_ADMIN"
    end
  end

  describe "InviteMemberWithRole" do
    test "it invites a member to a company with role: editor", %{
      context: context
    } do
      email = "paz@walnut.io"

      assert {:ok, query_data} =
               query_gql_by(
                 :invite_member,
                 variables: %{"email" => email, "role" => "EDITOR"},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "inviteMember"])

      assert result["id"] != nil
      assert result["email"] == email
      assert result["role"] == "EDITOR"
    end

    test "invite members authorization", %{context: context} do
      TestAccess.assert_roles(
        &query_gql_by(
          :invite_member,
          variables: %{"email" => Api.FixtureSequence.next("jaap") <> "@walnut.io"},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: false, editor: false, company_admin: true}
      )
    end
  end

  describe "BulkInviteMembers" do
    test "fails to invite if the company doesn't exist", %{
      context: context
    } do
      emails = ["paz@walnut.io", "tito@walnut.io"]

      assert {:ok, %{data: nil, errors: [%{code: :invalid_company_id}]}} =
               query_gql_by(
                 :bulk_invite_members,
                 variables: %{
                   "emails" => emails,
                   "companyId" => "f9a93cdf-760a-481b-8d69-43f2be99d3c9"
                 },
                 context: context
               )
    end

    test "fail to invite members already invited", %{
      context: context
    } do
      member =
        Api.Companies.member_from_user(context.current_user.id) |> Api.Repo.preload(:company)

      member_email = member.user.email

      emails = [member_email]

      fail_message = "#{member_email}: This email is already part of the team"

      assert {:ok, query_data} =
               query_gql_by(
                 :bulk_invite_members,
                 variables: %{
                   "emails" => emails,
                   "companyId" => member.company_id
                 },
                 context: context
               )

      result = get_in(query_data, [:data, "bulkInviteMembers"])

      assert result["invitesFailed"] == [fail_message]
    end

    test "it invites many members to a company without a role", %{
      context: context
    } do
      member =
        Api.Companies.member_from_user(context.current_user.id) |> Api.Repo.preload(:company)

      emails = ["paz@walnut.io", "tito@walnut.io"]

      assert {:ok, query_data} =
               query_gql_by(
                 :bulk_invite_members,
                 variables: %{"emails" => emails, "companyId" => member.company_id},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "bulkInviteMembers"])

      assert result["invitesFailed"] == []

      [first_invite, second_invite] = result["invitesSent"]
      assert first_invite["email"] == "tito@walnut.io"
      assert first_invite["role"] == "COMPANY_ADMIN"
      assert second_invite["email"] == "paz@walnut.io"
      assert second_invite["role"] == "COMPANY_ADMIN"
    end

    test "it invites many members to a company with role: editor", %{
      context: context
    } do
      member =
        Api.Companies.member_from_user(context.current_user.id) |> Api.Repo.preload(:company)

      emails = ["paz@walnut.io", "tito@walnut.io"]

      assert {:ok, query_data} =
               query_gql_by(
                 :bulk_invite_members,
                 variables: %{
                   "emails" => emails,
                   "role" => "EDITOR",
                   "companyId" => member.company_id
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "bulkInviteMembers"])

      assert result["invitesFailed"] == []

      [first_invite, second_invite] = result["invitesSent"]
      assert first_invite["email"] == "tito@walnut.io"
      assert first_invite["role"] == "EDITOR"
      assert second_invite["email"] == "paz@walnut.io"
      assert second_invite["role"] == "EDITOR"
    end
  end
end
