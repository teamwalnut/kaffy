defmodule Api.CustomDomains.CustomDomain do
  @moduledoc """
  Represents a custom domain of a customer
  """
  use Api.Schema
  alias Api.Companies.Company

  schema "custom_domains" do
    field(:domain, :string)
    field(:env, :string)

    belongs_to(:company, Company)

    timestamps()
  end

  # coveralls-ignore-start

  @deprecated "Don't use, hack to make Kaffy happy"
  def changeset(_custom_domain, _attrs) do
    %{}
  end

  # coveralls-ignore-stop

  @doc false
  def custom_domain_changeset(custom_domain, attrs) do
    custom_domain
    |> cast(attrs, [:domain, :env])
    |> validate_required([:domain, :company_id, :env])
    |> validate_format(
      :domain,
      ~r/^((?:([a-z0-9]\.|[a-z0-9][a-z0-9\-]{0,61}[a-z0-9])\.)+)([a-z0-9]{2,63}|(?:[a-z0-9][a-z0-9\-]{0,61}[a-z0-9]))$/
    )
    |> unique_constraint(:domain)
  end
end
