defmodule Api.Storylines.EditingTest do
  use Api.DataCase
  alias Api.Storylines.Editing
  alias Api.Storylines.Editing.Edit
  alias Api.Storylines.Editing.Edit.Link
  alias Api.Storylines.Editing.Edit.Link.ScreenDestination

  setup [:setup_user, :setup_company, :setup_member, :setup_public_storyline, :setup_screen]

  describe "storylines/edits" do
    test "list_edits/0 returns all edits for a screen", %{screen: screen} do
      edit =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "some new text",
          :text => "text"
        })

      assert Editing.list_edits(screen.id) == [edit]
    end

    test "list_edits_screen_by_kind/0 returns edits of specific kind for a screen", %{
      screen: screen
    } do
      edit1 =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "some new text",
          :text => "text"
        })

      edit2 =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "some new text",
          :text => "text"
        })

      _edit3 = Api.EditingFixtures.style_edit_fixture(screen.id)

      assert Editing.list_edits_screen_by_kind(screen.id, :text) == [edit1, edit2]
    end

    test "delete_edits/2 deletes only given edits", %{screen: screen, member: member} do
      edit =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "some new text",
          :text => "text"
        })

      edit2 =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "some new text",
          :text => "text"
        })

      Api.EditingFixtures.text_edit_fixture(screen.id, %{
        :original_text => "some new text",
        :text => "text"
      })

      assert {:ok, _deleted_edit} = Editing.delete_edits(screen.id, [edit, edit2], member)
      assert Enum.count(Editing.list_edits(screen.id)) == 1
    end

    test "update_edits/2 updates an edit", %{screen: screen, member: _member} do
      text_edit =
        create_edit(screen, :text, %{
          :original_text => "some new text",
          :text => "text"
        })

      assert {:ok, _result} =
               Editing.update_edits(
                 screen.id,
                 [
                   %{
                     id: text_edit.id,
                     kind: text_edit.kind,
                     css_selector: text_edit.css_selector,
                     frame_selectors: text_edit.frame_selectors,
                     text_edit_props: %{
                       original_text: text_edit.text_edit_props.original_text,
                       text: "new text edit"
                     },
                     last_edited_at: text_edit.last_edited_at
                   }
                 ]
               )

      edits = Editing.list_edits(screen.id)
      assert length(edits) == 1
      edit = edits |> Enum.at(0)

      assert %{
               text_edit_props: %{
                 original_text: _,
                 text: "new text edit"
               }
             } = edit
    end

    test "update_edits/2 updates an edit with dom selector", %{
      screen: screen,
      member: _member
    } do
      text_edit =
        create_edit(screen, :text, %{
          :original_text => "some new text",
          :text => "text"
        })

      assert {:ok, _result} =
               Editing.update_edits(
                 screen.id,
                 [
                   %{
                     id: text_edit.id,
                     kind: text_edit.kind,
                     css_selector: text_edit.css_selector,
                     frame_selectors: text_edit.frame_selectors,
                     dom_selector: %{
                       xpath_node: "xpath selector",
                       xpath_frames: []
                     },
                     text_edit_props: %{
                       original_text: text_edit.text_edit_props.original_text,
                       text: "new text edit"
                     },
                     last_edited_at: text_edit.last_edited_at
                   }
                 ]
               )

      edits = Editing.list_edits(screen.id)
      assert length(edits) == 1
      edit = edits |> Enum.at(0)

      assert %{
               dom_selector: %{
                 id: _,
                 xpath_frames: [],
                 xpath_node: "xpath selector"
               },
               text_edit_props: %{
                 original_text: _,
                 text: "new text edit"
               }
             } = edit
    end
  end

  describe "storylines/edits/text" do
    test "can create a text edit successfully", %{screen: screen} do
      attrs = %{
        :original_text => "some new text",
        :text => "text"
      }

      test_create_edit(screen, :text, attrs)
    end
  end

  describe "storylines/edits/html" do
    test "can create a html edit successfully", %{screen: screen} do
      attrs = %{
        :original_value => "html",
        :value => "some new html",
        :position => :after
      }

      test_create_edit(screen, :html, attrs)
    end

    test "can create an empty html edit successfully", %{screen: screen} do
      attrs = %{
        :original_value => "html",
        :value => "",
        :position => :after
      }

      test_create_edit(screen, :html, attrs)
    end
  end

  describe "storylines/edits/style" do
    test "can create a style edit succeessfully", %{screen: screen} do
      attrs = %{
        underline: true,
        bold: true,
        font_size: "18px",
        color: "#aaa"
      }

      test_create_edit(screen, :style, attrs)
    end
  end

  describe "storylines/edits/change_image" do
    test "can create a change_image edit successfully", %{
      screen: screen
    } do
      attrs = %{
        original_image_url: "original_image_url",
        image_url: "some_image_url"
      }

      test_create_edit(screen, :change_image, attrs)
    end
  end

  describe "storylines/edits/link/screen" do
    test "can add a link edit to a screen successfully", %{screen: screen} do
      edit = create_edit(screen, :link, %{destination: %{kind: "screen", id: screen.id}})

      assert edit |> Edit.props() |> Link.destination() == %ScreenDestination{
               kind: "screen",
               id: screen.id
             }
    end

    test "can add a link edit with delay_ms to a screen successfully", %{screen: screen} do
      edit =
        create_edit(screen, :link, %{
          delay_ms: 1000,
          destination: %{kind: "screen", id: screen.id}
        })

      assert edit |> Edit.props() |> Link.destination() == %ScreenDestination{
               kind: "screen",
               id: screen.id
             }
    end
  end

  describe "storylines/edits/link/screen/regression" do
    test "can add a link edit to a screen successfully", %{screen: screen} do
      edit =
        create_edit(screen, :link, %{
          delay_ms: 1000,
          destination: %{kind: "screen", id: screen.id}
        })

      # Converting the JSON to the old format
      Repo.query!("UPDATE edits SET link_edit_props = $1 WHERE id = $2", [
        %{target_screen_id: screen.id},
        Ecto.UUID.dump!(edit.id)
      ])

      loaded = Enum.at(Editing.list_edits(screen.id), 0)

      assert loaded |> Edit.props() |> Link.destination() == %ScreenDestination{
               kind: "screen",
               id: screen.id
             }
    end

    test "always write both new and old format using old format", %{screen: screen} do
      old_format_edit = create_edit(screen, :link, %{target_screen_id: screen.id})

      assert old_format_edit.link_edit_props == %Link{
               target_screen_id: screen.id,
               destination: %ScreenDestination{
                 kind: "screen",
                 id: screen.id
               }
             }
    end

    test "always write both new old format using new format", %{screen: screen} do
      new_format_edit =
        create_edit(screen, :link, %{destination: %{kind: "screen", id: screen.id}})

      assert new_format_edit.link_edit_props == %Link{
               target_screen_id: screen.id,
               destination: %ScreenDestination{
                 kind: "screen",
                 id: screen.id
               }
             }
    end

    test "should ignore nil values", %{screen: screen} do
      edit =
        create_edit(screen, :link, %{
          target_screen_id: nil,
          destination: %{kind: "screen", id: screen.id}
        })

      assert edit.link_edit_props == %Link{
               target_screen_id: screen.id,
               destination: %ScreenDestination{
                 kind: "screen",
                 id: screen.id
               }
             }
    end
  end

  describe "storylines/edits/scroll" do
    test "can create a scroll edit successfully", %{
      screen: screen
    } do
      test_create_edit(screen, :scroll, %{
        top: 100.0,
        left: 0.0
      })
    end
  end

  describe "storylines/edits/binding" do
    test "can create a binding edit successfully", %{
      screen: screen
    } do
      test_create_edit(screen, :binding, %{
        original_text: "hello world",
        program_embed:
          "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@args\":[{\"@name\":\"name\",\"@value\":\"name test\"},{\"@name\":\"defaultValue\",\"@value\":\"default value\"},{\"@name\":\"description\",\"@value\":\"desc\"}],\"@fnName\":\"PUBLIC_FIELD\",\"@id\":\"ef44f562-1d5e-4d38-bf59-7ef7a402380d\",\"@type\":\"Call\"}}"
      })
    end
  end

  defp create_edit(screen, kind, attrs) do
    kind_str = kind |> Atom.to_string()
    attrs_key = "#{kind_str}_edit_props" |> String.to_existing_atom()

    props =
      %{
        kind: kind,
        dom_selector: nil,
        css_selector: "some css selector",
        frame_selectors: ["iframe"],
        last_edited_at: DateTime.utc_now()
      }
      |> Map.put_new(attrs_key, attrs)

    {:ok, edit} = Editing.add_edit(screen.id, props)
    edit
  end

  defp attr_to_struct(kind, attrs) do
    module =
      "Elixir.Api.Storylines.Editing.Edit.#{kind |> Atom.to_string() |> Macro.camelize()}"
      |> String.to_existing_atom()

    struct(module, attrs)
  end

  defp test_create_edit(screen, kind, attrs) do
    edit = create_edit(screen, kind, attrs)

    module = attr_to_struct(kind, attrs)
    struct = struct(module, attrs)

    edit_props =
      if kind == :binding do
        props = Edit.props(edit)

        %Edit.Binding{
          original_text: props.original_text,
          program_embed: Jason.encode!(props.program_embed)
        }
      else
        Edit.props(edit)
      end

    assert edit_props == struct
  end
end
