defmodule Api.SSOTest do
  use Api.DataCase, async: true
  alias Api.SSO

  describe "sso" do
    setup [:setup_user, :setup_company, :setup_company_sso]

    test "get_company_sso_by_domain/1 returns company sso", %{
      company: company,
      company_sso: company_sso
    } do
      company_sso = SSO.get_company_sso_by_domain(company_sso.domain)
      assert company_sso.company_id == company.id
    end

    test "domain_from_email/1 returns correct domain out of an email" do
      assert SSO.domain_from_email("danni@walnut.io") == "walnut.io"
    end
  end
end
