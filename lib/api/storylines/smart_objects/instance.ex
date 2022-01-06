defmodule Api.Storylines.SmartObjects.Instance do
  @moduledoc false
  use Api.Schema

  alias Api.Storylines.Editing.Edit
  alias Api.Storylines.SmartObjects.Class

  @derive {Jason.Encoder,
           except: [
             :__struct__
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field(:class_id, :binary_id)
    field(:edits, {:array, :map})
    field(:edits_overrides, {:array, :map}, default: [])
    field(:css_selector, :string)
    field(:detached, :boolean, default: false)
    field(:frame_selectors, {:array, :string}, default: [])
    field(:screen_id, :string)
    field(:storyline_id, :string)

    embeds_one(:dom_selector, Api.DOMSelector, on_replace: :update)

    timestamps()
  end

  def of_class?(instance, %Class{} = class) do
    instance.class_id == class.id
  end

  def changeset(%__MODULE__{} = schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :class_id,
      :edits,
      :css_selector,
      :frame_selectors,
      :detached,
      :screen_id,
      :storyline_id,
      :edits_overrides
    ])
    |> cast_embed(:dom_selector)
    |> validate_required([
      :class_id,
      :css_selector,
      :frame_selectors,
      :edits,
      :screen_id,
      :storyline_id,
      :edits_overrides
    ])
    |> validate_edits()
  end

  defp validate_edits(%Ecto.Changeset{} = changeset) do
    edits = changeset |> get_field(:edits, [])

    case edits |> Edit.validate_many() do
      true -> changeset
      false -> changeset |> add_error(:edits, "invalid edits")
    end
  end

  @spec to_attributes(any() | [any()]) :: map() | [map()] | no_return()
  def to_attributes(value) do
    value |> Jason.encode!() |> Jason.decode!()
  end
end
