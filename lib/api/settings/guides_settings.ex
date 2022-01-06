defmodule Api.Settings.GuidesSettings do
  @moduledoc """
  These are the guides settings that are part of `Api.Settings.CompanySettings` and
  `Api.Settings.DemoVersionSettings`. The difference with `Api.Settings.StorylineGuidesSettings` is
  that almost all settings can NOT be null. Fields in this schema should not be nullable in the SQL schema,
  to guarantee this, even when adding new fields.
  The only fields in this schema that can be null are ["avatar_url", "avatar_title"].
  """
  use Api.Schema
  import Ecto.Changeset
  import Api.SchemaValidations

  alias Api.Settings.Items.DimStyle
  alias Api.Settings.Items.Fab

  @derive {Jason.Encoder,
           except: [
             :__meta__,
             :__struct__,
             :company_settings,
             :demo_version_settings
           ]}
  # NOTE(Jaap): when you add a new field, make sure the field is non-null in the migration (correct for most cases)
  schema "guides_settings" do
    field(:show_glow, :boolean)
    field(:glow_color, :string)
    field(:background_color, :string)
    field(:font_color, :string)
    field(:font_size, :integer)
    field(:accent_color, :string)
    field(:smooth_scrolling, :boolean)
    field(:show_dismiss_button, :boolean)
    field(:show_back_button, :boolean)
    field(:show_main_button, :boolean)
    field(:main_button_text, :string)
    field(:dim_by_default, :boolean)
    field(:dim_style, Ecto.Enum, values: DimStyle.kinds())
    field(:celebrate_guides_completion, :boolean)
    field(:show_avatar, :boolean)
    field(:avatar_url, :string)
    field(:avatar_title, :string)

    embeds_one(:fab, Fab, on_replace: :update)

    belongs_to(:company_settings, Api.Settings.CompanySettings)
    belongs_to(:demo_version_settings, Api.Settings.DemoVersionSettings)
  end

  def defaults do
    %__MODULE__{
      show_glow: true,
      glow_color: "#3b85e948",
      background_color: "#FFFFFF",
      font_color: "#292930",
      font_size: 12,
      accent_color: "#3B67E9",
      smooth_scrolling: true,
      show_dismiss_button: true,
      show_back_button: true,
      show_main_button: true,
      main_button_text: "Next",
      dim_by_default: false,
      dim_style: :medium,
      celebrate_guides_completion: true,
      show_avatar: false,
      avatar_url: nil,
      avatar_title: nil,
      fab: Fab.defaults()
    }
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [
      :show_glow,
      :glow_color,
      :background_color,
      :font_color,
      :font_size,
      :accent_color,
      :smooth_scrolling,
      :show_dismiss_button,
      :show_back_button,
      :show_main_button,
      :main_button_text,
      :dim_by_default,
      :dim_style,
      :celebrate_guides_completion,
      :show_avatar,
      :avatar_url,
      :avatar_title
    ])
    |> cast_embed(:fab, required: true, with: {Fab, :changeset_for_guides_settings, []})
    |> validate_required([
      :show_glow,
      :glow_color,
      :background_color,
      :font_color,
      :font_size,
      :accent_color,
      :smooth_scrolling,
      :show_dismiss_button,
      :show_back_button,
      :show_main_button,
      :main_button_text,
      :dim_by_default,
      :dim_style,
      :celebrate_guides_completion,
      :show_avatar
    ])
    |> validate_required_inclusion([:company_settings_id, :demo_version_settings_id])
    |> validate_format(:glow_color, hex_format_regex())
    |> validate_format(:background_color, hex_format_regex())
    |> validate_format(:font_color, hex_format_regex())
    |> validate_number(:font_size, greater_than_or_equal_to: 1)
    |> validate_format(:accent_color, hex_format_regex())
  end
end
