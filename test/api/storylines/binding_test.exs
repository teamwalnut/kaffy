defmodule Api.Storylines.BindingEditTest do
  use Api.DataCase
  alias Api.Storylines.Editing
  alias Api.Storylines.Editing.Edit
  alias Api.Storylines.Editing.Edit.Binding

  setup [:setup_user, :setup_company, :setup_member, :setup_public_storyline, :setup_screen]

  describe "binding edit updates" do
    test "update binding edit successfully with variables", %{
      screen: screen
    } do
      edit = create_binding_edit(screen)

      variables = [
        %{id: "123", name: "name test", value: "Marina"}
      ]

      Binding.update_binding_edits_with_variables(variables, [edit])
      updated_edit = Repo.get!(Edit, edit.id)
      args = updated_edit.binding_edit_props.program_embed.expression.args
      assert args |> Enum.count() == 3
      %{value: value} = args |> Enum.find(fn arg -> arg.name == "defaultValue" end)
      assert value == "Marina"
    end

    test "update only binding edits (not other kind of edits) successfully with variables", %{
      screen: screen
    } do
      scroll_edit =
        create_edit(screen, :scroll, %{
          top: 100.0,
          left: 0.0
        })

      edit1 = create_binding_edit(screen)
      edit2 = create_binding_edit(screen)

      variables = [
        %{id: "123", name: "name test", value: "Marina"}
      ]

      {:ok, result} =
        Binding.update_binding_edits_with_variables(variables, [edit1, edit2, scroll_edit])

      update_edits_ids =
        Map.keys(result)
        |> Enum.map(fn updated_edit -> elem(updated_edit, 1) end)

      assert update_edits_ids |> Enum.count() == 2
      assert update_edits_ids |> Enum.member?(edit1.id)
      assert update_edits_ids |> Enum.member?(edit2.id)
    end

    test "update only binding edits (not dates tokens) successfully with variables", %{
      screen: screen
    } do
      variables_token_edit = create_binding_edit(screen)

      date_token_edit =
        create_edit(screen, :binding, %{
          original_text: "hello world",
          program:
            "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@type\":\"Call\",\"@fnName\":\"DATE.CURRENT\",\"@id\":\"4d2b77a1-2c9a-4beb-bf34-6b727d5e4bae\",\"@args\":[{\"@name\":\"format\",\"@value\":\"DD/MM/YY\"}]}}"
        })

      variables = [
        %{id: "123", name: "name test", value: "Marina"}
      ]

      {:ok, result} =
        Binding.update_binding_edits_with_variables(variables, [
          variables_token_edit,
          date_token_edit
        ])

      update_edits_ids =
        Map.keys(result)
        |> Enum.map(fn updated_edit -> elem(updated_edit, 1) end)

      assert update_edits_ids |> Enum.count() == 1
      assert update_edits_ids |> Enum.member?(variables_token_edit.id)
    end

    test "don't update bind when variables list is empty", %{
      screen: screen
    } do
      edit = create_binding_edit(screen)

      Binding.update_binding_edits_with_variables([], [edit])
      edit = Repo.get!(Edit, edit.id)
      args = edit.binding_edit_props.program_embed.expression.args
      %{value: value} = args |> Enum.find(fn arg -> arg.name == "defaultValue" end)
      assert value == "default value"
    end

    test "don't update bind when variables list doesn't match edit arguments", %{
      screen: screen
    } do
      edit = create_binding_edit(screen)

      variables = [
        %{id: "123", name: "different name than arg in edit", value: "Marina"}
      ]

      Binding.update_binding_edits_with_variables(variables, [edit])
      edit = Repo.get!(Edit, edit.id)
      args = edit.binding_edit_props.program_embed.expression.args
      %{value: value} = args |> Enum.find(fn arg -> arg.name == "defaultValue" end)
      assert value == "default value"
    end
  end

  defp create_binding_edit(screen) do
    {:ok, edit} =
      Editing.add_edit(screen.id, %{
        kind: :binding,
        css_selector: "first",
        binding_edit_props: %{
          program:
            "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@args\":[{\"@name\":\"name\",\"@value\":\"name test\"},{\"@name\":\"defaultValue\",\"@value\":\"default value\"},{\"@name\":\"description\",\"@value\":\"desc\"}],\"@fnName\":\"PUBLIC_FIELD\",\"@id\":\"ef44f562-1d5e-4d38-bf59-7ef7a402380d\",\"@type\":\"Call\"}}",
          original_text: "original text"
        },
        last_edited_at: DateTime.utc_now()
      })

    edit
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
end
