defmodule Api.Annotations.Annotation do
  @moduledoc """
  Represents an Annotation,
  a piece of information anchored to an element in a screen - point annotation,
  or the whole screen - modal annotation.
  """

  use Api.Schema

  @position_index_basis 0

  @doc """
  Rich Text is being represented as Quill Delta format. For more info, please check https://quilljs.com/docs/delta/.
  """
  schema "annotations" do
    field(:kind, Ecto.Enum, values: [:point, :modal])
    field(:message, :string)
    field(:rich_text, :map)
    field(:step, :integer)
    field(:css_selector, :string)
    field(:frame_selectors, {:array, :string})

    field(:anchor, Ecto.Enum,
      values: [
        :top,
        :top_start,
        :top_end,
        :right,
        :bottom,
        :bottom_start,
        :bottom_end,
        :left,
        :auto
      ]
    )

    belongs_to(:screen, Api.Storylines.Screen)
    belongs_to(:guide, Api.Annotations.Guide)
    embeds_one(:settings, Api.Settings.AnnotationSettings, on_replace: :update)

    timestamps()
  end

  @doc """
    A changeset for creating a point/modal annotation based on the passed kind
  """
  def create_changeset(annotation, attrs, kind) when kind == :point do
    create_base_point_changeset(annotation, attrs)
    |> validate_unique_step()
  end

  def create_changeset(annotation, attrs, kind) when kind == :modal do
    create_base_modal_changeset(annotation, attrs)
    |> validate_unique_step()
  end

  @doc """
    A changeset for creating a point/modal annotation between existing annotations based on the passed kind
  """
  def create_between_steps_changeset(annotation, attrs, kind) when kind == :point do
    create_base_point_changeset(annotation, attrs)
    |> unique_constraint([:step, :guide_id],
      message: "can't have two annotations with the same step value in a guide"
    )
  end

  def create_between_steps_changeset(annotation, attrs, kind) when kind == :modal do
    create_base_modal_changeset(annotation, attrs)
    |> unique_constraint([:step, :guide_id],
      message: "can't have two annotations with the same step value in a guide"
    )
  end

  defp create_base_point_changeset(annotation, attrs) do
    annotation
    |> cast(attrs, [
      :message,
      :rich_text,
      :step,
      :css_selector,
      :frame_selectors,
      :anchor,
      :screen_id
    ])
    |> validate_required([
      :kind,
      :step,
      :screen_id,
      :guide_id,
      :css_selector,
      :frame_selectors,
      :anchor
    ])
    |> validate_required_inclusion([:rich_text, :message])
    |> validate_number(:step, greater_than_or_equal_to: 0)
    |> cast_settings
  end

  defp create_base_modal_changeset(annotation, attrs) do
    annotation
    |> cast(attrs, [
      :message,
      :rich_text,
      :step,
      :screen_id
    ])
    |> validate_required([:kind, :step, :screen_id, :guide_id])
    |> validate_required_inclusion([:rich_text, :message])
    |> validate_number(:step, greater_than_or_equal_to: 0)
    |> cast_settings
  end

  @doc false
  def update_changeset(annotation, attrs) do
    annotation
    |> cast(
      attrs,
      [
        :kind,
        :message,
        :rich_text,
        :css_selector,
        :frame_selectors,
        :anchor,
        :screen_id
      ],
      empty_values: ["message"]
    )
    |> put_change_per_kind()
    |> validate_required([:kind, :screen_id])
    |> validate_required_inclusion([:rich_text, :message])
    |> validate_required_per_kind()
    |> cast_settings
  end

  @doc false
  def delete_changeset(annotation) do
    annotation |> change
  end

  defp cast_settings(changeset) do
    changeset =
      if get_change(changeset, :settings) == nil do
        changeset |> put_change(:settings, %{})
      else
        changeset
      end

    changeset
    |> cast_embed(:settings, required: false)
  end

  @doc """
  Returns a changeset for repositioning an annotation.
  """
  def reposition_changeset(annotation, attrs) do
    annotation
    |> cast(attrs, [:step])
    |> validate_required(:step)
    |> validate_number(:step, greater_than_or_equal_to: 0)
    |> unique_constraint([:step, :annotation_id],
      message: "can't have 2 annotations in the same position"
    )
  end

  def defer_position_unique_constraint_query do
    "SET CONSTRAINTS annotations_step_annotation_id DEFERRED"
  end

  def all_guide_annotations_query(guide_id) do
    from(annotation in __MODULE__,
      where: annotation.guide_id == ^guide_id,
      order_by: [asc: annotation.step]
    )
  end

  def all_annotations_query do
    from(annotation in __MODULE__, order_by: [asc: annotation.step])
  end

  def annotations_in_screen_query(screen_id) do
    from(annotations in __MODULE__,
      where: annotations.screen_id == ^screen_id
    )
  end

  def all_next_annotations_query(guide_id, step_number) do
    from(annotation in __MODULE__,
      where: annotation.guide_id == ^guide_id and annotation.step >= ^step_number,
      order_by: [asc: annotation.step]
    )
  end

  def all_annotations_in_screens_query(screen_ids) do
    from(annotations in __MODULE__,
      where: annotations.screen_id in ^screen_ids,
      order_by: [asc: annotations.guide_id, asc: annotations.step]
    )
  end

  defp validate_unique_step(changeset) do
    changeset
    |> unsafe_validate_unique([:step, :guide_id], Api.Repo,
      message: "can't have two annotations with the same step value in a guide"
    )
    |> unique_constraint([:step, :guide_id],
      message: "can't have two annotations with the same step value in a guide"
    )
  end

  defp validate_required_per_kind(changeset) do
    case Ecto.Changeset.get_field(changeset, :kind) do
      :point ->
        changeset
        |> validate_required([:css_selector, :frame_selectors, :anchor])

      _ ->
        changeset
    end
  end

  defp put_change_per_kind(changeset) do
    case Ecto.Changeset.get_field(changeset, :kind) do
      :modal ->
        changeset
        |> put_change(:anchor, nil)
        |> put_change(:css_selector, nil)
        |> put_change(:frame_selectors, nil)

      _ ->
        changeset
    end
  end

  def position_index_basis do
    @position_index_basis
  end
end
