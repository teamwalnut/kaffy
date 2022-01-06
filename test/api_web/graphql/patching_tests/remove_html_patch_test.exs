defmodule ApiWeb.GraphQL.RemoveHtmlPatchTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :remove_patch,
    ApiWeb.Schema,
    "test/support/mutations/patching/RemovePatch.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide,
    :setup_storyline_html_patch
  ]

  describe "RemoveHtmlPatchTest" do
    test "removes a html patch", %{
      context: context,
      storyline_html_patch: storyline_html_patch
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :remove_patch,
                 variables: %{"patchId" => storyline_html_patch.id},
                 context: context
               )

      no_errors!(query_data)
    end

    test "authorization", %{
      context: context,
      storyline_html_patch: storyline_html_patch
    } do
      TestAccess.assert_roles(
        &query_gql_by(
          :remove_patch,
          variables: %{"patchId" => storyline_html_patch.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
