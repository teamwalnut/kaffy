defmodule Api.Companies.MemberInvite do
  @moduledoc false
  use Api.Schema

  alias Api.Companies.MemberInvite

  @hash_algorithm :sha256
  @rand_size 32
  @thirty_days_in_seconds 2_592_000

  schema("member_invites") do
    field(:email, :string)
    field(:token, :binary)
    field(:expires_at, :utc_datetime)
    field(:role, Ecto.Enum, values: [:company_admin, :editor, :viewer, :presenter])

    belongs_to(:company, Api.Companies.Company)
    belongs_to(:member, Api.Companies.Member)

    timestamps()
  end

  @doc """
  Builds the MemeberInvite changeset and creates and sets token
  returns a tuple with {"some_encoded_token", changeset}
  """
  def build_invitation(attrs) do
    %MemberInvite{}
    |> cast(attrs, [:email, :company_id, :role])
    |> validate_required([:company_id, :role])
    |> validate_email()
    |> unsafe_validate_unique([:email, :company_id], Api.Repo,
      message: "This email has already been invited"
    )
    |> unique_constraint([:email, :company_id], message: "This email has already been invited")
    |> set_expires_at()
    |> build_and_set_token()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  defp set_expires_at(changeset) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@thirty_days_in_seconds, :second)

    changeset
    |> cast(%{expires_at: expires_at}, [:expires_at])
  end

  defp build_and_set_token(changeset) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {
      Base.url_encode64(token, padding: false),
      put_change(changeset, :token, hashed_token)
    }
  end

  @doc """
  decodes the token and builds a query to find an active MemberInvite by the token
  """
  def find_by_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from(member_invite in MemberInvite,
            where:
              member_invite.token == ^hashed_token and
                is_nil(member_invite.member_id) and
                member_invite.expires_at > from_now(1, "second"),
            select: member_invite
          )

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Mark the invitation as accepted by setting `member_id`.
  """
  def accept_invitation_changeset(member_invite, attrs) do
    member_invite
    |> cast(attrs, [:member_id])
    |> validate_required([:member_id])
  end
end
