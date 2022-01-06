defmodule Api.Kaffy.Accounts.UserAdmin do
  @moduledoc false
  alias Api.Accounts.User

  def form_fields(_) do
    [
      email: %{create: :editable, update: :readonly},
      first_name: nil,
      last_name: nil,
      password: nil,
      is_admin: %{type: :boolean}
    ]
  end

  def index(_) do
    [
      email: nil,
      name: %{name: "Full name", value: fn u -> "#{u.first_name} #{u.last_name}" end},
      is_admin: %{
        name: "Admin?",
        value: fn u -> if u.is_admin, do: "✅", else: "❌" end
      }
    ]
  end

  def delete(conn, _changeset) do
    user = Api.Accounts.get_user!(conn.params["id"])
    Api.Repo.delete(user)
  end

  def update(_conn, changeset) do
    Api.Repo.update(changeset)
  end

  def create_changeset(schema, attrs) do
    User.admin_create_changeset(schema, attrs)
  end

  def update_changeset(%Api.Accounts.User{} = user, attrs) do
    changeset = User.admin_update_changeset(user, attrs)

    if Ecto.Changeset.get_change(changeset, :password) != nil && changeset.valid? == true do
      Api.Accounts.delete_all_tokens(user)
    end

    changeset
  end
end
