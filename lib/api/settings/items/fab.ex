defmodule Api.Settings.Items.Fab do
  @moduledoc """
  A setting item for the FAB(Floating Action Button) configuration.
  A FAB can be used to show a button on a demo that, on click, allows to open a new tab
  """
  use Api.Schema

  alias Api.Settings.Cascade

  @position [:top_left, :top_right, :bottom_right, :bottom_left]
  @derive {Jason.Encoder,
           except: [
             :__struct__
           ]}
  @primary_key false
  embedded_schema do
    field(:enabled, :boolean)
    field(:position, Ecto.Enum, values: @position)
    field(:text, :string, size: 25)
    field(:target_url, EctoFields.URL)
  end

  def changeset_for_guides_settings(schema, attrs) do
    schema
    |> cast(attrs, [
      :enabled,
      :position,
      :text,
      :target_url
    ])
    |> validate_state_for_guides_settings
  end

  defp validate_state_for_guides_settings(changeset) do
    if changeset |> get_change(:enabled) == true do
      changeset |> validate_required([:position, :text, :target_url])
    else
      changeset
    end
  end

  def changeset_for_storyline_guides_settings(schema, attrs) do
    schema
    |> cast(attrs, [
      :enabled,
      :position,
      :text,
      :target_url
    ])
    |> validate_state_for_storyline_guides_settings
  end

  defp validate_state_for_storyline_guides_settings(changeset) do
    if changeset |> get_change(:enabled) == true do
      changeset |> validate_required([:text, :target_url])
    else
      changeset
    end
  end

  def defaults do
    %__MODULE__{
      enabled: false,
      position: :bottom_right,
      text: nil,
      target_url: nil
    }
  end

  def cascade(first, second, default) do
    %__MODULE__{
      first
      | enabled: Cascade.three_way_merge(first, second, default, :enabled),
        position: Cascade.three_way_merge(first, second, default, :position),
        text: Cascade.three_way_merge(first, second, default, :text),
        target_url: Cascade.three_way_merge(first, second, default, :target_url)
    }
  end
end
