defmodule Api.Settings.StorylineSettings do
  @moduledoc """
  User settings for the storyline
  """
  use Api.Schema
  import Ecto.Changeset
  alias Api.Settings.{Cascade, CompanySettings, StorylineGuidesSettings}

  @foreign_key_type :binary_id

  schema "storyline_settings" do
    field(:global_js, :string)
    field(:global_css, :string)
    field(:main_color, :string)
    field(:secondary_color, :string)
    field(:disable_loader, :boolean)

    belongs_to(:storyline, Api.Storylines.Storyline)
    has_one(:guides_settings, StorylineGuidesSettings, on_replace: :update)

    timestamps()
  end

  def create_changeset(settings, attrs) do
    settings
    |> cast(attrs, [
      :storyline_id,
      :global_js,
      :global_css,
      :main_color,
      :secondary_color,
      :disable_loader
    ])
    |> cast_assoc(:guides_settings, with: &StorylineGuidesSettings.changeset/2)
    |> validate_required([:storyline_id, :guides_settings])
    |> unsafe_validate_unique([:storyline_id], Api.Repo,
      message: "can't have more than 1 settings per storyline"
    )
    |> unique_constraint([:storyline_id],
      message: "can't have more than 1 settings per storyline"
    )
    |> validate_color_fields()
  end

  @doc false
  def update_changeset(settings, attrs) do
    settings
    |> cast(attrs, [
      :global_js,
      :global_css,
      :main_color,
      :secondary_color,
      :disable_loader
    ])
    |> cast_assoc(:guides_settings, with: &StorylineGuidesSettings.changeset/2)
    |> validate_color_fields()
  end

  defp validate_color_fields(changeset) do
    changeset
    |> validate_format(:main_color, hex_format_regex())
    |> validate_format(:secondary_color, hex_format_regex())
  end

  def cascade(storyline_settings, company_settings) do
    default = CompanySettings.defaults()

    %__MODULE__{
      id: storyline_settings && storyline_settings.id,
      global_css: storyline_settings && storyline_settings.global_css,
      global_js: storyline_settings && storyline_settings.global_js,
      main_color:
        Cascade.three_way_merge(storyline_settings, company_settings, default, :main_color),
      secondary_color:
        Cascade.three_way_merge(storyline_settings, company_settings, default, :secondary_color),
      disable_loader:
        Cascade.three_way_merge(storyline_settings, company_settings, default, :disable_loader),
      guides_settings:
        StorylineGuidesSettings.cascade(
          storyline_settings &&
            storyline_settings.guides_settings,
          company_settings && company_settings.guides_settings
        )
    }
  end
end
