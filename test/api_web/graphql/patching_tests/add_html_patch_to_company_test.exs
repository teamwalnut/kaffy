defmodule ApiWeb.GraphQL.AddCompanyHtmlPatchTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :add_html_patch_to_company,
    ApiWeb.Schema,
    "test/support/mutations/patching/AddHtmlPatchToCompany.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide
  ]

  describe "AddCompanyHtmlPatchTest" do
    test "adds a html patch to a company", %{
      context: context,
      company: company
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :add_html_patch_to_company,
                 variables: %{
                   "name" => "test",
                   "companyId" => company.id,
                   "htmlPatch" => %{
                     "cssSelector" => "html > body",
                     "html" => "<div>yes</div>",
                     "position" => "APPEND_CHILD",
                     "targetUrlGlob" => "passarinho"
                   }
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "addHtmlPatchToCompany"])
      assert result["id"] != nil
    end

    test "authorization", %{context: context, company: company} do
      TestAccess.assert_roles(
        &query_gql_by(
          :add_html_patch_to_company,
          variables: %{
            "name" => "test",
            "companyId" => company.id,
            "htmlPatch" => %{
              "cssSelector" => "html > body",
              "html" => "<div>yes</div>",
              "position" => "APPEND_CHILD",
              "targetUrlGlob" => "passarinho"
            }
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: false, editor: false, company_admin: true}
      )
    end
  end
end
