defmodule ApiWeb.Schema.AccountTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  input_object :user_accept_invite_props do
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:password, non_null(:string))
    field(:password_confirmation, non_null(:string))
  end

  @desc "A user of Walnut"
  object :user do
    field(:email, non_null(:string))
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:is_admin, non_null(:boolean))
    field(:confirmed_at, :string)

    field(:members, list_of(non_null(:member)), resolve: dataloader(:member))
    field(:companies, list_of(non_null(:company)), resolve: dataloader(:company))
  end

  object :account_mutations do
    @desc "Sends a reset password email to the user by email"
    field :send_reset_password_email, non_null(:string) do
      arg(:email, non_null(:string))

      resolve(fn _parent, %{email: email} = attrs, %{context: _context} ->
        case Api.Accounts.get_user_by_email(email) do
          nil ->
            Logger.warn("No user found with email: #{email}")

          %User{} = user ->
            {:ok, encoded_token} = Api.Accounts.create_reset_password_token(user)
            ApiWeb.Emails.Users.reset_password(user, email, encoded_token)
            |> Api.Mailer.deliver_later!()
        end

        {:ok, email}
    end
  end

  object :account_queries do
    field :current_user, :user do
      resolve(fn
        _, _, %{context: %{current_user: current_user}} ->
          {:ok, current_user}

        _, _, _ ->
          {:error, :unauthorized}
      end)
    end
  end
end
