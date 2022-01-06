defmodule ApiWeb.DemoTest do
  use ApiWeb.ConnCase, async: true
  import Api.DemosFixtures
  import Api.StorylinesFixtures
  import Api.CustomDomainsFixtures

  describe "GET /demo/" do
    setup [
      :setup_company,
      :setup_user,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :setup_demo,
      :setup_custom_domain
    ]

    test "returns 403 if demo is not authorized to be served behind a domain", %{
      conn: conn,
      demo: demo,
      custom_domain: custom_domain
    } do
      conn = get(%{conn | host: "#{custom_domain.domain}extra"}, "/demo/", %{demoId: demo.id})
      assert response(conn, 403)
    end

    test "returns 200 if demo exist and authorized to be served behind a domain", %{
      conn: conn,
      demo: demo,
      custom_domain: custom_domain
    } do
      conn =
        get(%{conn | host: custom_domain.domain}, "/demo/", %{
          demoId: demo.id,
          hideGuidesToolbar: "true"
        })

      assert html_response(conn, 200) =~
               "src=\"https://app.testwalnut.com/demo/?demoId=#{demo.id}&amp;hideGuidesToolbar=true\""
    end
  end
end
