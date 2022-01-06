defmodule Api.CustomDomainsTest do
  use Api.DataCase, async: true

  alias Api.CustomDomains
  alias Api.CustomDomains.CustomDomain

  setup [
    :setup_user,
    :setup_company,
    :setup_member,
    :setup_public_storyline,
    :setup_multiple_screens,
    :setup_demo,
    :setup_custom_domain
  ]

  describe "demo_domain?/2" do
    test "it returns true when company owns the domain", %{
      company: company,
      custom_domain: custom_domain
    } do
      assert CustomDomains.demo_domain?(company.id, custom_domain.domain) == true
      assert CustomDomains.demo_domain?(company.id, "#{custom_domain.domain}x") == false
    end
  end

  describe "delete/1" do
    test "it deletes a custom domain", %{
      custom_domain: custom_domain
    } do
      assert {:ok, %CustomDomain{}} = CustomDomains.delete!(custom_domain.id)

      assert %Ecto.NoResultsError{} = catch_error(CustomDomains.delete!(custom_domain.id))
    end
  end
end
