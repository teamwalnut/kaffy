defmodule Api.Storylines.SmartObjects.Class do
  @moduledoc false
  use Api.Schema
  alias Api.Storylines.Editing.Edit

  @derive {Jason.Encoder,
           except: [
             :__meta__,
             :__struct__,
             :storyline
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "smart_object_classes" do
    field(:name, :string)
    field(:thumbnail, :string)
    field(:edits, {:array, :map})
    field(:css_selector, :string)
    field(:frame_selectors, {:array, :string}, default: [])
    field(:archived_at, :utc_datetime_usec, default: nil)

    embeds_one(:dom_selector, Api.DOMSelector, on_replace: :update)

    belongs_to(:storyline, Api.Storylines.Storyline)
    timestamps()
  end

  def list_not_archived_query(storyline_id) do
    from(smart_object_class in __MODULE__,
      where:
        smart_object_class.storyline_id == ^storyline_id and
          is_nil(smart_object_class.archived_at),
      order_by: [asc: :inserted_at]
    )
  end

  def create_changeset(%__MODULE__{} = schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [:name, :thumbnail, :css_selector, :edits, :frame_selectors, :storyline_id])
    |> cast_embed(:dom_selector)
    |> validate_required([
      :name,
      :thumbnail,
      :css_selector,
      :edits,
      :frame_selectors,
      :storyline_id
    ])
    |> validate_edits()
  end

  def update_changeset(%__MODULE__{} = schema, attrs) do
    schema
    |> cast(attrs, [:name, :thumbnail, :edits, :css_selector, :frame_selectors, :archived_at])
    |> cast_embed(:dom_selector)
    |> validate_required([
      :name,
      :thumbnail,
      :css_selector,
      :edits,
      :frame_selectors,
      :storyline_id
    ])
    |> validate_edits()
  end

  def archive_changeset(%__MODULE__{} = schema) do
    update_changeset(schema, %{archived_at: DateTime.utc_now()})
    |> validate_required([:archived_at])
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
