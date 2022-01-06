defmodule Api.Companies do
  @moduledoc """
  The Companies context, allows you to interact with companies and members.
  A Member is an instance of a User that belongs(a member of) to a company.
  """

  import Ecto.Query, warn: false
  alias Api.Repo

  alias Api.Companies.{Company, Member}

  @doc """
  Gets a single company.

  Raises `Ecto.NoResultsError` if the Company does not exist.

  ## Examples

      iex> get_company!(123)
      %Company{}

      iex> get_company!(456)
      ** (Ecto.NoResultsError)

  """
  def get_company!(id), do: Repo.get!(Company, id)

  def get_company(id) do
    case Repo.get(Company, id) do
      nil -> {:error, :company_not_found}
      company -> {:ok, company}
    end
  end

  @doc """
  Creates a company.

  ## Examples

      iex> create_company(%{field: value})
      {:ok, %Company{}}

      iex> create_company(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_company(attrs) do
    %Company{}
    |> Company.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a company.

  ## Examples

      iex> update_company(company, %{field: new_value})
      {:ok, %Company{}}

      iex> update_company(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_company(%Company{} = company, attrs) do
    company
    |> Company.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a company.

  ## Examples

      iex> delete_company(company)
      {:ok, %Company{}}

      iex> delete_company(company)
      {:error, %Ecto.Changeset{}}

  """
  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  @doc """
  Returns the list of members.

  ## Examples

      iex> list_members(company)
      [%Member{}, ...]

  """
  def list_members(company) do
    company = company |> Repo.preload(:members)
    company.members
  end

  @doc """
  Gets a single member.

  Raises `Ecto.NoResultsError` if the Member does not exist.

  ## Examples

      iex> get_member!(123)
      %Member{}

      iex> get_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_member!(id),
    do: Member |> Repo.get!(id)

  @doc """
  Gets a member that belongs to the passed company_id
  and related to a user that has the specific passed email

  ## Examples

      iex> get_member_by_email("some@email.com", company_id)
      %Member{}

      iex> get_member_by_email("non_existing@email.com", company_id)
      nil

  """
  def get_member_by_email(email, company_id) do
    Repo.one(Member.member_by_email_and_company_id_query(email, company_id))
  end

  @doc """
  Creates a member.

  ## Examples

      iex> add_member(user_id, %Api.Companies.Company{}, %{field: value})
      {:ok, %Member{}}

      iex> add_member(user_id, %Api.Companies.Company{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add_member(user_id, %Api.Companies.Company{} = company, attrs \\ %{}) do
    if member_from_user(user_id) == nil do
      %Member{user_id: user_id, company_id: company.id, role: :company_admin}
      |> Member.create_changeset(attrs)
      |> Repo.insert()
    else
      {:error, "user already a member of a company"}
    end
  end

  @doc """
  Returns a member from a given user.

  ## Examples

    iex> member_from_user(user_id)
    {:ok, %Member{}}

  """
  def member_from_user(user_id) do
    Repo.get_by(Member, user_id: user_id) |> Repo.preload(:user)
  end

  @doc """
  Deletes a member.

  ## Examples

      iex> delete_member(member, actor)
      {:ok, %Member{}}

      iex> delete_member(member, actor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_member(%Member{} = member, actor) do
    member = Repo.preload(member, [:company])

    with :ok <- Api.Authorizer.authorize(member.company, actor, :admin) do
      Repo.delete(member)
    end
  end

  defp last_admin?(%Member{} = member) do
    if Member.is_admin?(member) do
      member = member |> Repo.preload(:company)

      member.company
      |> list_members
      |> Enum.filter(&Member.is_admin?(&1))
      |> Enum.count() == 1
    else
      false
    end
  end

  @doc """
  Updates a member's role

  ## Examples

        iex> update_member_role(member, valid_attr)
        {:ok, %Storyline{}}

        iex> update_member_role(member, invalid_attrs)
        {:error, %Ecto.Changeset{}}

  """
  def update_member_role(%Member{} = member, role) do
    if last_admin?(member) && role != :company_admin do
      {:error,
       "You cannot downgrade this user since a company must have at lease one Admin. Set a different admin to downgrade this user."}
    else
      member
      |> Member.update_changeset(%{role: role})
      |> Repo.update()
    end
  end
end
