defmodule Api.CustomDomainsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.CustomDomains` context.
  """

  def unique_domain, do: "#{Api.FixtureSequence.next("domain")}.com"

  def custom_domain_fixture(company, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        domain: unique_domain(),
        env: "test"
      })

    {:ok, custom_domain} =
      company.id
      |> Api.CustomDomains.create_custom_domain(attrs)

    custom_domain
  end

  def setup_custom_domain(%{company: company} = attrs) do
    {:ok, custom_domain: custom_domain_fixture(company, attrs)}
  end
end
