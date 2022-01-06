defmodule Api.Accounts.Compliance do
  @moduledoc """
  The Compliance context, holds information about
  how we comply to laws regarding our users.
  For example, approving our Terms and Conditions, GDPR, privacy, etc.
  """
  use Api.Schema

  @primary_key false
  schema "compliances" do
    field :tac_approved_at, :utc_datetime_usec
    belongs_to(:user, Api.Accounts.User)
    timestamps()
  end

  @doc """
  Returns a changeset for creating a compliance.
  """
  def create_changeset(compliance, attrs) do
    compliance
    |> cast(attrs, [])
    |> set_approved_at()
    |> validate_required([:user, :tac_approved_at])
  end

  defp set_approved_at(changeset) do
    changeset |> put_change(:tac_approved_at, DateTime.utc_now())
  end
end
