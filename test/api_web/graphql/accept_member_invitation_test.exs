defmodule ApiWeb.GraphQL.AcceptMemberInvitation do
  use ApiWeb.GraphQLCase

  @user_attributes %{
    first_name: "Paz",
    last_name: "Pagaz",
    password: "1234567891011",
    password_confirmation: "1234567891011"
  }

  load_gql(
    :accept_member_invitation,
    ApiWeb.Schema,
    "test/support/mutations/AcceptMemberInvitation.gql"
  )

  setup do
    user = user_fixture()
    %{member: member, company: company} = company_and_member_fixture(user)
    {:ok, %{encoded_token: token}} = Api.MemberInvite.invite_member("paz@walut.io", member)

    {:ok, token: token, company: company}
  end

  describe "AcceptMemberInvitation" do
    test "it accepts the invitation and updates the invited member's user attributes", %{
      token: token,
      company: company
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :accept_member_invitation,
                 variables: %{
                   "token" => token,
                   "firstName" => @user_attributes[:first_name],
                   "lastName" => @user_attributes[:last_name],
                   "password" => @user_attributes[:password],
                   "passwordConfirmation" => @user_attributes[:password_confirmation]
                 },
                 context: %{}
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "acceptMemberInvitation"])
      user_result = result["user"]
      company_result = result["company"]

      assert user_result["email"] == "paz@walut.io"
      assert user_result["firstName"] == @user_attributes[:first_name]
      assert user_result["lastName"] == @user_attributes[:last_name]
      assert user_result["confirmedAt"] != nil
      assert company_result["id"] == company.id
    end
  end
end
