defmodule Api.SSO do
  @moduledoc """
  Handles SSO stuff for a company.
  We currently attach SSO data to a company
  """
  alias Api.Repo
  alias Api.SSO.CompanySSO

  @doc """
  Gets a single company by its associated domain

  ## Examples

      iex> get_company_sso_by_domain("walnut.io")
      %CompanySSO{}

      iex> get_company_sso_by_domain("oh-no-no.com")
      nil

  """
  def get_company_sso_by_domain(domain), do: Repo.get_by(CompanySSO, domain: domain)

  @doc """
  Gets the domain from an email.

  ## Examples

    iex> domain_from_email("danni@walnut.io")
    walnut.io
  """
  # Note(Danni): not sure this is the best place for it, but couldn't find a better one
  def domain_from_email(email), do: email |> String.split("@") |> List.last()
end
