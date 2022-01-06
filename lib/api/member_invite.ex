defmodule Api.MemberInvite do
  @moduledoc """
  Responsible for the flow of inviting a member to a company.
  This flow has it's own context since it envolves working with the Companies and Accounts contexts
  """

  import Ecto.Query, warn: false
  alias Api.Repo
  alias Ecto.Multi

  alias Api.Accounts
  alias Api.Companies
  alias Api.Companies.Member

  @doc """
  Gets a single MemberInvite by id.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_member_invite!(123)
      %User{}

      iex> get_member_invite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_member_invite!(id), do: Repo.get!(Companies.MemberInvite, id)

  @doc """
  Creates a MemberInvite for the  given email.

  ## Examples

      iex> invite_member("some@email.com", actor)
      {:ok, %{member_invite: %Api.Companies.MemberInvite{}, encoded_token: "random_token"}}

      iex> invite_member("bad_email", actor)
      {:error, %Ecto.Changeset{}}

      iex> invite_member("already_exists@email.com", actor)
      {:error, %Ecto.Changeset{}}

      iex> invite_member("", actor)
      {:error, %Ecto.Changeset{}}
  """
  def invite_member(email, %Member{} = actor, role \\ :company_admin) do
    actor = Repo.preload(actor, [:company])

    with :ok <- Api.Authorizer.authorize(actor.company, actor, :admin) do
      case Companies.get_member_by_email(email, actor.company_id) do
        nil ->
          {encoded_token, member_invitation_changeset} =
            Companies.MemberInvite.build_invitation(%{
              email: email,
              company_id: actor.company_id,
              role: role
            })

          case Repo.insert(member_invitation_changeset) do
            {:ok, member_invite} ->
              {:ok, %{member_invite: member_invite, encoded_token: encoded_token}}

            {:error, errored_changeset} ->
              {:error, errored_changeset}
          end

        %Companies.Member{} = _existing_member ->
          {:error, "This email is already part of the team"}
      end
    end
  end

  @doc """
  Creates a MemberInvite for the given company_id and given email.

  ## Examples

      iex> invite_member("some@email.com", "f65150e8-df1e-420b-afb6-c048674c1cd7")
      {:ok, %{member_invite: %Api.Companies.MemberInvite{}, encoded_token: "random_token"}}

      iex> invite_member("bad_email", "f65150e8-df1e-420b-afb6-c048674c1cd7")
      {:error, %Ecto.Changeset{}}

      iex> invite_member("already_exists@email.com", "f65150e8-df1e-420b-afb6-c048674c1cd7")
      {:error, %Ecto.Changeset{}}

      iex> invite_member("", "f65150e8-df1e-420b-afb6-c048674c1cd7")
      {:error, %Ecto.Changeset{}}
  """
  def invite_member_for_company(email, company_id, role \\ :company_admin) do
    case Companies.get_member_by_email(email, company_id) do
      nil ->
        {encoded_token, member_invitation_changeset} =
          Companies.MemberInvite.build_invitation(%{
            email: email,
            company_id: company_id,
            role: role
          })

        case Repo.insert(member_invitation_changeset) do
          {:ok, member_invite} ->
            {:ok, %{member_invite: member_invite, encoded_token: encoded_token}}

          {:error, errored_changeset} ->
            {:error, errored_changeset}
        end

      %Companies.Member{} = _existing_member ->
        {:error, "#{email}: This email is already part of the team"}
    end
  end

  @doc """
  Tries to find the MemberInvite by the token
  if it can't, it returns an error
  if it can, it creats a User record with the provided user_attrs
  and a Member record for that User and the MemberInvite's company
  and sets the member_id attribute on the MemberInvite
  """
  def accept_member_invitation(token, user_attrs) do
    case find_member_invite_by_token(token) do
      %Companies.MemberInvite{} = member_invite ->
        apply_accept_invite_multi(member_invite, user_attrs)

      nil ->
        {:error, "Invitation either doesn't exist, expired, or already accepted"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp find_member_invite_by_token(token) do
    case Companies.MemberInvite.find_by_token_query(token) do
      {:ok, query} -> Repo.one(query)
      _ -> {:error, "Invalid invite token"}
    end
  end

  defp apply_accept_invite_multi(%Companies.MemberInvite{} = member_invite, user_attrs) do
    company = Companies.get_company!(member_invite.company_id)

    Multi.new()
    |> Multi.run(:user, fn _repo, _changes_so_far ->
      updated_user_attrs = user_attrs |> Map.put(:email, member_invite.email)
      Accounts.accept_user_invitation(updated_user_attrs)
    end)
    |> Multi.run(:member, fn _repo, %{user: user} ->
      Companies.add_member(user.id, company, %{role: member_invite.role})
    end)
    |> Multi.run(:member_invite, fn _repo, %{member: member} ->
      Companies.MemberInvite.accept_invitation_changeset(member_invite, %{
        member_id: member.id
      })
      |> Repo.update()
    end)
    |> Repo.transaction()
  end

  @doc """
  Deletes a MemberInvite.

  ## Examples

      iex> delete_member_invite(member_invite, actor)
      {:ok, %Member{}}

      iex> delete_member_invite(member_invite, actor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_member_invite(%Companies.MemberInvite{} = member_invite, actor) do
    member_invite = Repo.preload(member_invite, :company)

    with :ok <- Api.Authorizer.authorize(member_invite.company, actor, :admin) do
      Repo.delete(member_invite)
    end
  end
end
