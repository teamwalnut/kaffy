defmodule Api.CompanySSOFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Demos` context.
  """

  alias Api.Companies.Company
  alias Api.Repo
  alias Api.SSO.CompanySSO

  def unique_domain, do: "#{Api.FixtureSequence.next("test")}.com"
  def unique_workos_org_id, do: "#{Api.FixtureSequence.next("workos_org_")}"
  def unique_workos_conn_id, do: "#{Api.FixtureSequence.next("workos_conn_")}"

  def company_sso_fixture(%Company{} = company, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        domain: unique_domain(),
        workos_org_id: unique_workos_org_id(),
        workos_conn_id: unique_workos_conn_id()
      })

    {:ok, company_sso} =
      %CompanySSO{company_id: company.id}
      |> CompanySSO.create_changeset(attrs)
      |> Repo.insert()

    company_sso
  end

  def setup_company_sso(%{company: company}) do
    company_sso = company_sso_fixture(company)
    {:ok, company_sso: company_sso}
  end
end
