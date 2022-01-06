defmodule ApiWeb.Emails.CompaniesTest do
  use Api.DataCase

  alias Api.MemberInvite
  alias ApiWeb.Emails

  test "invite_member/4" do
    user = user_fixture()
    %{member: member, company: company} = company_and_member_fixture(user)

    {:ok, %{member_invite: member_invite, encoded_token: token}} =
      MemberInvite.invite_member("paz@walnut.io", member)

    email = Emails.Companies.invite_member(company, member_invite.email, token)

    assert email.to == member_invite.email
    assert email.from == {"Walnut", "hello@walnut.io"}
    assert email.headers["Reply-To"] == "noreply@walnut.io"
    assert email.subject == "You are invited to join #{company.name} on Walnut 🥳"
    assert email.assigns[:invite_url] == "https://app.teamwalnut.com/accept_invite?token=#{token}"

    assert email.html_body =~
             "You’re invited to join our company team on Walnut!"
  end
end
