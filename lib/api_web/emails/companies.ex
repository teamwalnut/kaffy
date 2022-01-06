defmodule ApiWeb.Emails.Companies do
  @moduledoc """
  This module is responsible for creating emails thats related to companies
  """
  use Bamboo.Phoenix, view: ApiWeb.EmailView

  alias Api.Companies

  @email_from {"Walnut", "hello@walnut.io"}
  @reply_to "noreply@walnut.io"

  def invite_member(%Companies.Company{} = company, email, token) do
    base_email(email)
    |> subject("You are invited to join #{company.name} on Walnut 🥳")
    |> put_html_layout({ApiWeb.EmailView, "layout.html"})
    |> assign(:invite_url, "https://app.teamwalnut.com/accept_invite?token=#{token}")
    |> render("companies/invite_member.html")
  end

  defp base_email(email) do
    new_email(
      from: @email_from,
      to: email
    )
    |> put_header("Reply-To", @reply_to)
  end
end
