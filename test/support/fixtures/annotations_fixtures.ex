defmodule Api.AnnotationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Annotations` context.
  """

  alias Api.Annotations
  alias Api.Repo

  def guide_fixture(storyline, attrs \\ %{}) do
    valid_attrs = %{
      name: "#{Api.FixtureSequence.next("guide_")}"
    }

    attrs = Enum.into(attrs, valid_attrs)
    storyline = storyline |> Repo.preload(owner: [:user, :company])

    {:ok, guide} = Annotations.create_guide(storyline.id, attrs, storyline.owner)

    guide
  end

  def annotation_point_fixture(guide, screen_id, actor, attrs \\ %{}) do
    valid_attrs = %{
      kind: :point,
      message: "some message",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z",
      screen_id: screen_id,
      frame_selectors: ["iframe"],
      css_selector: "some css selector",
      anchor: :top
    }

    attrs = Enum.into(attrs, valid_attrs)
    {:ok, annotation} = Annotations.add_annotation_to_guide(guide.id, attrs, :point, actor)

    Api.Repo.get!(Annotations.Annotation, annotation.id)
  end

  def annotation_modal_fixture(guide, screen_id, actor, attrs \\ %{}) do
    valid_attrs = %{
      kind: :modal,
      message: "some message",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z",
      screen_id: screen_id
    }

    attrs = Enum.into(attrs, valid_attrs)
    {:ok, annotation} = Annotations.add_annotation_to_guide(guide.id, attrs, :modal, actor)

    Api.Repo.get!(Annotations.Annotation, annotation.id)
  end

  def setup_guide(%{public_storyline: public_storyline}) do
    {:ok, guide: guide_fixture(public_storyline, %{name: "Guide 1"})}
  end

  def setup_point_annotation(%{guide: guide, screen: screen, member: member}) do
    {:ok, annotation: annotation_point_fixture(guide, screen.id, member)}
  end

  def setup_modal_annotation(%{guide: guide, screen: screen, member: member}) do
    {:ok, annotation: annotation_modal_fixture(guide, screen.id, member)}
  end

  def setup_multiple_annotations(%{guide: guide, screen: screen, member: member}) do
    annotations =
      []
      |> List.insert_at(-1, annotation_modal_fixture(guide, screen.id, member))
      |> List.insert_at(-1, annotation_modal_fixture(guide, screen.id, member))
      |> List.insert_at(-1, annotation_modal_fixture(guide, screen.id, member))
      |> List.insert_at(-1, annotation_modal_fixture(guide, screen.id, member))

    {:ok, annotations: annotations}
  end
end
