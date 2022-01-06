defmodule Api.SSO.CompanySSO do
  @moduledoc """
  Represent SSO related data for a company
  """
  use Api.Schema

  alias Api.Companies.Company

  schema "company_sso" do
    field(:domain, :string)
    field(:workos_org_id, :string)
    field(:workos_conn_id, :string)

    belongs_to(:company, Company)

    timestamps()
  end

  @deprecated "Don't use, hack to make Kaffy happy"
  def changeset(_company, _attrs) do
    %{}
  end

  @doc false
  def create_changeset(company_sso, attrs) do
    company_sso
    |> cast(attrs, [:domain, :workos_org_id, :workos_conn_id])
    |> validate_required([:domain, :workos_org_id, :workos_conn_id])
    |> unique_constraint(:workos_org_id)
    |> unique_constraint(:workos_conn_id)
    |> unique_constraint(:domain)
    |> foreign_key_constraint(:company_id)
  end
end
