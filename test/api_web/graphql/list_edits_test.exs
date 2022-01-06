defmodule ApiWeb.GraphQL.ListEditsTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines.Editing
  load_gql(ApiWeb.Schema, "test/support/queries/ScreenEdits.gql")
  setup [:register_and_log_in_member]

  describe "addEditsToScreen" do
    test "it should append edits correctly depending on their type", %{
      context: context,
      member: member
    } do
      storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
      screen = storyline |> Api.StorylinesFixtures.screen_fixture()

      {:ok, _edits} =
        Editing.add_edits(
          screen.id,
          [
            %{
              kind: :text,
              frame_selectors: [],
              css_selector: ".text",
              dom_selector: %{
                xpath_node: "div",
                xpath_frames: []
              },
              last_edited_at: DateTime.utc_now(),
              text_edit_props: %{
                original_text: "original text",
                text: "text"
              }
            },
            %{
              kind: :style,
              frame_selectors: [],
              css_selector: ".style",
              dom_selector: %{
                xpath_node: "div",
                xpath_frames: []
              },
              last_edited_at: DateTime.utc_now(),
              style_edit_props: %{
                bold: true,
                color: "#ssss",
                font_size: "10px",
                underline: true
              }
            }
          ]
        )

      result = query_gql(variables: %{"id" => storyline.id}, context: context)

      assert {:ok, query_data} = result
      no_errors!(query_data)

      edits =
        get_in(query_data, [:data, "storyline", "screens"]) |> Enum.at(0) |> get_in(["edits"])

      assert edits == [
               %{
                 "frameSelectors" => [],
                 "cssSelector" => ".text",
                 "domSelector" => %{"xpathNode" => "div", "xpathFrames" => []}
               },
               %{
                 "frameSelectors" => [],
                 "cssSelector" => ".style",
                 "domSelector" => %{"xpathNode" => "div", "xpathFrames" => []}
               }
             ]
    end
  end
end
