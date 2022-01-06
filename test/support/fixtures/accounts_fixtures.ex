defmodule Api.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password(),
        first_name: "my name is",
        last_name: "slim shady"
      })
      |> Api.Accounts.register_user()

    user
  end

  def user_admin_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    Ecto.Changeset.cast(user, %{is_admin: true}, [:is_admin])
    |> Api.Repo.update!()
  end

  def setup_user(attrs \\ %{}) do
    {:ok, user: user_fixture(attrs)}
  end

  # @spec extract_user_token((any -> any)) :: binary
  # def extract_user_token(fun) do
  #   {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
  #   [_, token, _] = String.split(captured.body, "[TOKEN]")
  #   token
  # end
end
