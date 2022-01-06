defmodule Api.Storylines.SmartObjectInstancesTest do
  use Api.DataCase, async: true
  alias Api.Storylines.SmartObjects
  alias Api.Storylines.SmartObjects.Class

  describe "smart objects instances" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen
    ]

    @edits [
      %{
        "frame_selectors" => nil,
        "css_selector" => "asdasd",
        "kind" => "text",
        "text_edit_props" => %{"original_text" => "original text", "text" => "new text"}
      }
    ]

    test "list smart object instances should retrun an empty array", %{
      screen: screen
    } do
      {:ok, screen_id} = Ecto.UUID.cast(screen.id)
      {:ok, list} = SmartObjects.list_instances(screen_id)
      assert list == []
    end

    test "create and retrieve smart object instances", %{
      public_storyline: storyline,
      screen: screen,
      member: member
    } do
      {:ok, smart_object_class} =
        SmartObjects.create_class(
          %Class{
            storyline_id: storyline.id,
            name: "test smart object",
            thumbnail: "===",
            css_selector: "div > div",
            edits: @edits
          },
          member
        )

      {:ok, _smart_object_instances} =
        SmartObjects.update_instances_in_screen(
          screen.id,
          [
            %{
              class_id: smart_object_class.id,
              css_selector: "div > div",
              frame_selectors: [],
              edits: @edits,
              edits_overrides: []
            }
          ],
          member
        )

      {:ok, list} = SmartObjects.list_instances(screen.id)
      assert length(list) == 1
    end
  end
end
