defmodule Mix.Tasks.GlobalLinks do
  @moduledoc """
  Task to copy link edits from one screen to all others.
  Currently we've clients that want to have a single menu work across their entire demo.
  Unfortunatly, in our system right now, they'll have to go into each screen and add the edits.
  So what we're doing with them, is that we tell them: create one screen with the edits as you want them, and we'll magically
  apply these edits to all other screens - this script helps with that.

  You set
    - @storyline - The storyline to copy screens to
    - @edited_screen - The screen with the edits

  Also note: is_valid_edit? to filter which edits to copy, in case there are a bunch of other edits you dont want to coffee.
  """
  use Mix.Task

  alias Api.Storylines.Editing
  alias Ecto.Multi

  @storyline "put-id-here"
  @edited_screen "put-id-here"

  def run(_args) do
    :dev = Mix.env()
    Mix.Task.run("app.start")

    {:ok, _} =
      Multi.new()
      |> Multi.run(:storyline, fn _repo, _args ->
        {:ok, Api.Storylines.get_storyline!(@storyline)}
      end)
      |> Multi.run(:edits_to_add, fn _repo, %{storyline: _storyline} ->
        screen = Api.Storylines.get_screen!(@edited_screen)

        {:ok,
         Editing.list_edits(screen.id)
         |> Enum.filter(&is_valid_edit?/1)}
      end)
      |> Multi.run(:target_screens, fn _repo, %{storyline: storyline} ->
        {:ok,
         Api.Storylines.list_screens(storyline)
         |> Enum.filter(fn screen ->
           screen.id != @edited_screen
         end)}
      end)
      |> Multi.merge(fn %{target_screens: screens, edits_to_add: edits} ->
        edits =
          edits
          |> Enum.map(fn edit ->
            %{
              css_selector: edit.css_selector,
              frame_selectors: edit.frame_selectors,
              kind: edit.kind,
              last_edited_at: edit.last_edited_at,
              change_image_edit_props: from_struct(edit.change_image_edit_props),
              html_edit_props: from_struct(edit.html_edit_props),
              link_edit_props: from_struct(edit.link_edit_props),
              scroll_edit_props: from_struct(edit.scroll_edit_props),
              style_edit_props: from_struct(edit.style_edit_props),
              text_edit_props: from_struct(edit.text_edit_props)
            }
          end)

        screens
        |> Enum.reduce(
          Multi.new(),
          fn screen, acc ->
            acc
            # credo:disable-for-next-line
            |> Multi.run("add_screen_#{screen.id}", fn _repo, _changes ->
              Editing.add_edits(screen.id, edits)
            end)
          end
        )
      end)
      |> Multi.run(:note, fn _repo, %{target_screens: screens, edits_to_add: edits} ->
        Mix.shell().info("""
            Screens: #{screens |> Enum.count()} edits: #{edits |> Enum.count()}
        """)

        {:ok, ""}
      end)
      |> Api.Repo.transaction(timeout: :infinity)
  end

  defp from_struct(nil) do
    nil
  end

  defp from_struct(param) do
    param |> Map.from_struct()
  end

  defp is_valid_edit?(_edit) do
    true
  end
end
