defmodule ApiWeb.Emails.Users do
  @moduledoc """
  This module is responsible for creating emails thats related to users
  """
  use Bamboo.Phoenix, view: ApiWeb.EmailView

  alias Api.Accounts

  # TODO(Roland): check the email address we wanna send this from
  @email_from {"Walnut", "hello@walnut.io"}
  @reply_to "noreply@walnut.io"

  # TODO(Roland): document this function
  def reset_password(%Accounts.User{} = user, email, token) do
    base_email(email)
    |> subject("You are invited to join #{user.name} on Walnut 🥳")
    |> put_html_layout({ApiWeb.EmailView, "layout.html"})
    |> assign(:invite_url, "https://app.teamwalnut.com/reset_password?token=#{token}")
    |> render("users/reset_password.html")
  end

  # TODO(Roland): this should be extracted as it's the same as in companies.ex
  defp base_email(email) do
    new_email(
      from: @email_from,
      to: email
    )
    |> put_header("Reply-To", @reply_to)
  end
end
