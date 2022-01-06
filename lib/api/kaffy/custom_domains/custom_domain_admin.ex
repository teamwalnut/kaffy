defmodule Api.Kaffy.CustomDomains.CustomDomainAdmin do
  @moduledoc false

  alias Api.Companies.Company
  alias Api.CustomDomains
  alias Api.CustomDomains.CustomDomain
  alias Api.Repo

  def form_fields(_) do
    companies = Repo.all(Company)
    companies_options = Enum.map(companies, fn x -> {x.name, x.id} end)

    [
      domain: %{create: :editable, update: :readonly},
      company_id: %{choices: companies_options, create: :editable, update: :hidden}
    ]
  end

  def insert(conn, _changeset) do
    env = System.get_env("ENVIRONMENT") || "prod"
    params = conn.params["custom_domain"]

    domain_name = params["domain"]

    company =
      params["company_id"]
      |> Api.Companies.get_company!()

    company.id |> CustomDomains.create_custom_domain(%{domain: domain_name, env: env})
  end

  def delete(conn, _changeset) do
    domain_id = conn.params["id"]
    CustomDomains.delete!(domain_id)
  end

  def create_changeset(schema, attrs) do
    CustomDomain.custom_domain_changeset(schema, attrs)
  end

  def update_changeset(schema, attrs) do
    CustomDomain.custom_domain_changeset(schema, attrs)
  end
end
