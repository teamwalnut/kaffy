defmodule ApiWeb.GraphQL.AddStorylineHtmlPatchTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :add_html_patch_to_storyline,
    ApiWeb.Schema,
    "test/support/mutations/patching/AddHtmlPatchToStoryline.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide
  ]

  describe "AddStorylineHtmlPatchTest" do
    test "adds a html patch to a storyline", %{
      context: context,
      public_storyline: public_storyline
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :add_html_patch_to_storyline,
                 variables: %{
                   "name" => "test",
                   "storylineId" => public_storyline.id,
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
      result = get_in(query_data, [:data, "addHtmlPatchToStoryline"])
      assert result["id"] != nil
    end

    test "authorization", %{
      context: context,
      public_storyline: public_storyline
    } do
      TestAccess.assert_roles(
        &query_gql_by(
          :add_html_patch_to_storyline,
          variables: %{
            "name" => "test",
            "storylineId" => public_storyline.id,
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
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
