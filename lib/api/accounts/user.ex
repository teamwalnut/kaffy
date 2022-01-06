defmodule Api.Accounts.User do
  @moduledoc false
  use Api.Schema
  alias Api.Accounts.Compliance

  @derive {Inspect, except: [:password]}
  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password, :string, virtual: true)
    field(:hashed_password, :string)
    field(:confirmed_at, :naive_datetime)
    field(:is_admin, :boolean, redact: true)
    has_many(:members, Api.Companies.Member)
    has_many(:companies, through: [:members, :company])
    has_one(:compliance, Compliance)
    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name])
    |> validate_required([:password, :first_name, :last_name])
    |> validate_email()
    |> validate_password()
  end

  # coveralls-ignore-start
  def admin_create_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :is_admin])
    |> validate_required([:password, :first_name, :last_name])
    |> validate_email()
    |> validate_admin_domain()
    |> validate_password()
  end

  def admin_update_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :is_admin])
    |> validate_required([:first_name, :last_name])
    |> validate_email()
    |> validate_admin_domain()
    |> validate_password()
  end

  defp validate_admin_domain(changeset) do
    is_admin = get_change(changeset, :is_admin, false)

    email_domain = (get_field(changeset, :email) || "") |> String.split("@") |> List.last()

    if is_admin == true && email_domain != "walnut.io" do
      changeset |> add_error(:is_admin, "cannot set is_admin for non walnut emails")
    else
      changeset
    end
  end

  # coveralls-ignore-stop

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Api.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 12, max: 80)
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password != nil do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def is_admin_changeset(user, attrs) do
    user |> cast(attrs, [:is_admin]) |> validate_required([:is_admin])
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Api.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  A user changeset for user invitation acceptance.
  """
  def accept_invitation_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name])
    |> validate_required([:first_name, :last_name])
    |> validate_confirmation(:password, message: "does not match password", required: true)
    |> validate_email()
    |> validate_password()
    |> confirm_changeset()
  end
end
