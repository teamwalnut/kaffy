defmodule Api.EditingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Editing` context.
  """
  alias Api.Storylines.Editing

  def unique_css_selector,
    do: "#{Api.FixtureSequence.next("storyline_")}"

  def text_edit_fixture(screen_id, attrs) do
    props = %{
      kind: :text,
      dom_selector: nil,
      frame_selectors: [unique_css_selector()],
      css_selector: unique_css_selector(),
      last_edited_at: DateTime.utc_now(),
      text_edit_props: attrs
    }

    {:ok, edit} = Editing.add_edit(screen_id, props)

    Api.Repo.get!(Editing.Edit, edit.id)
  end

  def style_edit_fixture(screen_id, attrs \\ %{}) do
    attrs =
      Map.merge(attrs, %{
        underline: true,
        bold: false,
        font_size: "22px",
        color: "redr"
      })

    props = %{
      kind: :style,
      dom_selector: nil,
      frame_selectors: [unique_css_selector()],
      css_selector: unique_css_selector(),
      last_edited_at: DateTime.utc_now(),
      style_edit_props: attrs
    }

    {:ok, edit} = Editing.add_edit(screen_id, props)

    Api.Repo.get!(Editing.Edit, edit.id)
  end

  def screen_link_edit_fixture(screen_id, target_screen_id, attrs \\ %{}) do
    attrs =
      Map.merge(attrs, %{
        destination: %{
          kind: "screen",
          id: target_screen_id,
          delay_ms: 2000
        }
      })

    props = %{
      kind: :link,
      dom_selector: nil,
      frame_selectors: [unique_css_selector()],
      css_selector: unique_css_selector(),
      last_edited_at: DateTime.utc_now(),
      link_edit_props: attrs
    }

    {:ok, edit} = Editing.add_edit(screen_id, props)

    Api.Repo.get!(Editing.Edit, edit.id)
  end

  def url_link_edit_fixture(screen_id, attrs \\ %{}) do
    attrs =
      Map.merge(attrs, %{
        destination: %{
          kind: "url",
          href: "https://google.com",
          target: :new_tab
        }
      })

    props = %{
      kind: :link,
      dom_selector: nil,
      frame_selectors: [unique_css_selector()],
      css_selector: unique_css_selector(),
      last_edited_at: DateTime.utc_now(),
      link_edit_props: attrs
    }

    {:ok, edit} = Editing.add_edit(screen_id, props)

    Api.Repo.get!(Editing.Edit, edit.id)
  end
end
