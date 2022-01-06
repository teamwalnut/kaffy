defmodule Api.CustomDomains do
  @moduledoc """
  The CustomDomain context, allows you to interact with custom domains.
  """
  use Api.Schema

  import Ecto.Query, warn: false

  alias Api.CustomDomains.CustomDomain
  alias Api.Repo

  @doc """
  Returns true if demo can be served under domain.

  ## Examples

    iex> demo_domain?("existing_company_id", "example.com")
    true

  """
  def demo_domain?(company_id, domain_name) do
    custom_domain = Repo.get_by(CustomDomain, domain: domain_name)

    if custom_domain != nil do
      custom_domain.company_id == company_id
    else
      false
    end
  end

  @doc """
  Creates a custom_domain.

  ## Examples

      iex> create_custom_domain("existing-company-uuid", %{domain: "example.com", env: "env"})
      {:ok, %CustomDomain{}}

      iex> create_custom_domain("unknown-comany-uuid", %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_custom_domain(company_id, attrs) do
    %CustomDomain{company_id: company_id}
    |> CustomDomain.custom_domain_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a CustomDomain.

  ## Examples

      iex> delete!("existing-custom-domain-id")
      %CustomDomain{}

  """
  def delete!(domain_id) do
    Repo.get!(CustomDomain, domain_id) |> Api.Repo.delete()
  end
end
