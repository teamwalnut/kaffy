defmodule Api.Companies.Company do
  @moduledoc """
  Represents a Company signed up to our service
  """
  use Api.Schema

  schema "companies" do
    field(:name, :string)
    field(:is_paying, :boolean, default: false)
    field(:is_locked, :boolean, default: false)

    has_many(:members, Api.Companies.Member)
    has_many(:member_invites, Api.Companies.MemberInvite)
    has_many(:patches, Api.Patching.Patch)
    has_one(:settings, Api.Settings.CompanySettings)
    has_one(:custom_domain, Api.CustomDomains.CustomDomain)

    has_one(:sso, Api.SSO.CompanySSO)

    timestamps()
  end

  @deprecated "Don't use, hack to make Kaffy happy"
  def changeset(_company, _attrs) do
    %{}
  end

  @doc false
  def create_changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :is_paying])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @doc false
  def update_changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :is_paying, :is_locked])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
