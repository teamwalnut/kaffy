defmodule ApiWeb.GraphQL.UpdateHtmlPatchTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :update_html_patch,
    ApiWeb.Schema,
    "test/support/mutations/patching/UpdateHtmlPatch.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide,
    :setup_storyline_html_patch
  ]

  describe "UpdateHtmlPatchTest" do
    test "updates a html patch data", %{
      context: context,
      storyline_html_patch: storyline_html_patch
    } do
      assert storyline_html_patch.data.html != "<div>yes</div>"

      assert {:ok, query_data} =
               query_gql_by(
                 :update_html_patch,
                 variables: %{
                   "patchId" => storyline_html_patch.id,
                   "htmlPatchData" => %{
                     "cssSelector" => "html > body",
                     "html" => "<div>yes</div>",
                     "position" => "APPEND_CHILD",
                     "targetUrlGlob" => "passarinho"
                   }
                 },
                 context: context
               )

      no_errors!(query_data)

      update_html_patch = Api.Patching.get_patch!(storyline_html_patch.id)

      assert update_html_patch.id == storyline_html_patch.id
      assert update_html_patch.data.html == "<div>yes</div>"
    end

    test "authorization", %{context: context, storyline_html_patch: storyline_html_patch} do
      TestAccess.assert_roles(
        &query_gql_by(
          :update_html_patch,
          variables: %{
            "patchId" => storyline_html_patch.id,
            "htmlPatchData" => %{
              "cssSelector" => "html > body",
              "html" => "<div>yes</div>",
              "position" => "APPEND_CHILD",
              "targetUrlGlob" => "passarinho"
            }
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
