defmodule Api.Settings.StorylineGuidesSettings do
  @moduledoc """
  These are the guides settings for a storyline. The difference with `Api.Settings.GuideSettings`
  is that in this schema null values are allowed, if a value is null the value will be cascaded
  from the `Api.Settings.CompanySettings` using the `cascade` function.
  """

  use Api.Schema
  import Ecto.Changeset
  import Api.SchemaValidations

  alias Api.Settings.Cascade
  alias Api.Settings.Items.DimStyle
  alias Api.Settings.Items.Fab

  @derive {Jason.Encoder,
           except: [
             :storyline_settings,
             :__meta__,
             :__struct__
           ]}
  # NOTE(Jaap): this fields need to allow null values, for cascading
  schema "storyline_guides_settings" do
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

    belongs_to(:storyline_settings, Api.Settings.StorylineSettings)
  end

  def defaults do
    %{
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
    |> cast_embed(:fab, required: false, with: {Fab, :changeset_for_storyline_guides_settings, []})
    |> validate_format(:glow_color, hex_format_regex())
    |> validate_format(:background_color, hex_format_regex())
    |> validate_format(:font_color, hex_format_regex())
    |> validate_number(:font_size, greater_than_or_equal_to: 1)
    |> validate_format(:accent_color, hex_format_regex())
  end

  def cascade(nil, _), do: defaults()

  def cascade(first, second) do
    default = defaults()

    %__MODULE__{
      first
      | show_glow: Cascade.three_way_merge(first, second, default, :show_glow),
        glow_color: Cascade.three_way_merge(first, second, default, :glow_color),
        background_color: Cascade.three_way_merge(first, second, default, :background_color),
        font_color: Cascade.three_way_merge(first, second, default, :font_color),
        font_size: Cascade.three_way_merge(first, second, default, :font_size),
        accent_color: Cascade.three_way_merge(first, second, default, :accent_color),
        smooth_scrolling: Cascade.three_way_merge(first, second, default, :smooth_scrolling),
        show_dismiss_button:
          Cascade.three_way_merge(first, second, default, :show_dismiss_button),
        show_back_button: Cascade.three_way_merge(first, second, default, :show_back_button),
        show_main_button: Cascade.three_way_merge(first, second, default, :show_main_button),
        main_button_text: Cascade.three_way_merge(first, second, default, :main_button_text),
        dim_by_default: Cascade.three_way_merge(first, second, default, :dim_by_default),
        dim_style: Cascade.three_way_merge(first, second, default, :dim_style),
        celebrate_guides_completion:
          Cascade.three_way_merge(first, second, default, :celebrate_guides_completion),
        show_avatar: Cascade.three_way_merge(first, second, default, :show_avatar),
        avatar_url: Cascade.three_way_merge(first, second, default, :avatar_url),
        avatar_title: Cascade.three_way_merge(first, second, default, :avatar_title),
        fab: Fab.cascade(first.fab, second && second.fab, default.fab)
    }
  end
end
