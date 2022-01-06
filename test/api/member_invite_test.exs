defmodule Api.MemberInviteTest do
  use Api.DataCase, async: true

  alias Api.Accounts
  alias Api.Companies
  alias Api.MemberInvite

  @valid_invited_user_attributes %{
    first_name: "Paz",
    last_name: "Aricha",
    password: "1234567891011",
    password_confirmation: "1234567891011"
  }

  @invalid_invited_user_attributes %{
    first_name: "Paz",
    last_name: "Aricha",
    password: "1234567891011",
    password_confirmation: "1110987654321"
  }

  describe "invite_member/2" do
    test "returns the encoded invite token if all operations were successful" do
      user = user_fixture()
      %{member: member} = company_and_member_fixture(user)

      assert {:ok, %{member_invite: _, encoded_token: _}} =
               MemberInvite.invite_member("paz@walnut.io", member)
    end

    test "returns the error if a user with the same email has a member that already belongs to that company" do
      existing_email = "paz@walnut.io"
      user = user_fixture(%{email: existing_email})
      %{member: member} = company_and_member_fixture(user)

      assert {:error, "This email is already part of the team"} ==
               MemberInvite.invite_member(existing_email, member)
    end

    test "returns the error for invalid email" do
      user = user_fixture()
      %{member: member} = company_and_member_fixture(user)
      {:error, changeset} = MemberInvite.invite_member("pazwalnut", member)
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end
  end

  describe "accept_member_invitation/2" do
    test "returns the created user, the create member and the update member_invite if passed with a valid token and all required user attributes" do
      user = user_fixture()
      %{member: member} = company_and_member_fixture(user)

      {:ok, %{encoded_token: token}} = MemberInvite.invite_member("paz@walnut.io", member)

      assert {:ok,
              %{
                user: %Accounts.User{},
                member: %Companies.Member{},
                member_invite: %Companies.MemberInvite{}
              }} = MemberInvite.accept_member_invitation(token, @valid_invited_user_attributes)
    end

    test "creates a user with the invite email and the passed attributes if passed with a valid token and all required user attributes" do
      user = user_fixture()
      %{member: member} = company_and_member_fixture(user)

      {:ok, %{encoded_token: token}} = MemberInvite.invite_member("paz@walnut.io", member)

      {:ok, %{user: user}} =
        MemberInvite.accept_member_invitation(token, @valid_invited_user_attributes)

      assert user.first_name == @valid_invited_user_attributes[:first_name]
      assert user.last_name == @valid_invited_user_attributes[:last_name]
      assert user.hashed_password != nil
      assert user.confirmed_at != nil
    end

    test "creates a member that connects the created user to the company if passed with a valid token and all required user attributes" do
      user = user_fixture()
      %{member: member, company: company} = company_and_member_fixture(user)

      {:ok, %{encoded_token: token}} =
        MemberInvite.invite_member("paz@walnut.io", member, :viewer)

      {:ok, %{user: user, member: member}} =
        MemberInvite.accept_member_invitation(token, @valid_invited_user_attributes)

      assert member.user_id == user.id
      assert member.company_id == company.id
      assert member.role == :viewer
    end

    test "creates a member that connects the created user to the company with default role admin" do
      user = user_fixture()
      %{member: member, company: company} = company_and_member_fixture(user)

      {:ok, %{encoded_token: token}} = MemberInvite.invite_member("paz@walnut.io", member)

      {:ok, %{user: user, member: member}} =
        MemberInvite.accept_member_invitation(token, @valid_invited_user_attributes)

      assert member.user_id == user.id
      assert member.company_id == company.id
      assert member.role == :company_admin
    end

    test "update the member_invite with the created member.id if passed with a valid token and all required user attributes" do
      user = user_fixture()
      %{member: member} = company_and_member_fixture(user)

      {:ok, %{member_invite: initial_member_invite, encoded_token: token}} =
        MemberInvite.invite_member("paz@walnut.io", member, :editor)

      assert initial_member_invite.member_id == nil

      {:ok, %{member_invite: updated_member_invite, member: member}} =
        MemberInvite.accept_member_invitation(token, @valid_invited_user_attributes)

      assert updated_member_invite.member_id == member.id
      assert updated_member_invite.role == member.role
    end

    test "connects the member to an existing user if such already exists and updates details" do
      email = "paz@walnut.io"
      new_password = "new_password"
      user = user_fixture()
      %{member: member} = company_and_member_fixture(user)
      user = user_fixture(%{email: email})

      {:ok, %{encoded_token: token}} = MemberInvite.invite_member(email, member)

      {:ok, %{user: created_user, member: member}} =
        MemberInvite.accept_member_invitation(token, %{
          first_name: "danni",
          last_name: "friedland",
          password: new_password,
          password_confirmation: new_password
        })

      assert created_user.id == user.id
      assert member.user_id == user.id
      user = Accounts.get_user_by_email_and_password(email, new_password)
      assert user.first_name == "danni"
      assert user.last_name == "friedland"
    end

    test "returns error with the errored changeset if user attributes are invalid" do
      user = user_fixture()
      %{member: member} = company_and_member_fixture(user)

      {:ok, %{encoded_token: token}} = MemberInvite.invite_member("paz@walnut.io", member)

      assert {:error, :user, %Ecto.Changeset{} = user_changeset, _} =
               MemberInvite.accept_member_invitation(token, @invalid_invited_user_attributes)

      assert elem(user_changeset.errors[:password_confirmation], 0) == "does not match password"
    end

    test "returns :error if the passed token doesn't belong to a user" do
      assert {:error, "Invitation either doesn't exist, expired, or already accepted"} ==
               MemberInvite.accept_member_invitation(
                 "random_token",
                 @valid_invited_user_attributes
               )
    end
  end

  describe "delete_member_invite/1" do
    test "deletes the member_invite" do
      user = user_fixture()
      %{member: member} = company_and_member_fixture(user)

      {:ok, %{member_invite: member_invite}} = MemberInvite.invite_member("paz@walnut.io", member)

      assert {:ok, %Companies.MemberInvite{}} =
               MemberInvite.delete_member_invite(member_invite, member)

      assert_raise Ecto.NoResultsError, fn ->
        Api.MemberInvite.get_member_invite!(member_invite.id)
      end
    end
  end
end
