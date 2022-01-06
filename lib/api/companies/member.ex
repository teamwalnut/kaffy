defmodule Api.Companies.Member do
  @moduledoc """
  A member of a company, this model is what connects a Api.Accounts.User to a Company and stores, handles everything relevant to this connection
  """
  use Api.Schema

  schema "members" do
    field(:role, Ecto.Enum, values: [:company_admin, :editor, :presenter, :viewer])

    belongs_to(:user, Api.Accounts.User)
    belongs_to(:company, Api.Companies.Company)

    timestamps()
  end

  @doc false
  def create_changeset(member, attrs) do
    member
    |> cast(attrs, [:role])
    |> validate_required([:company_id, :user_id])
    |> unique_constraint(:user_id, name: :members_user_id_company_id_index)
  end

  def update_changeset(member, attrs) do
    member
    |> cast(attrs, [:role])
    |> validate_required([:id])
  end

  @doc """
  Returns a query that finds a member that belongs to a the passed company_id
  and related to a user that has the specific passed email
  """
  def member_by_email_and_company_id_query(email, company_id) do
    from(
      member in Api.Companies.Member,
      join: user in Api.Accounts.User,
      on: member.user_id == user.id,
      where:
        user.email == ^email and
          member.company_id == ^company_id,
      select: member
    )
  end

  @doc """
  Returns if member is an admin
  """
  def is_admin?(member) do
    member.role == :company_admin
  end
end
