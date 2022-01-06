defmodule Api.Settings.CompanySettings do
  @moduledoc """
  Default settings for the company
  """
  use Api.Schema
  import Ecto.Changeset
  alias Api.Settings.GuidesSettings

  schema "company_settings" do
    field(:main_color, :string, default: "#6E1DF4")
    field(:secondary_color, :string, default: "#3B67E9")
    field(:disable_loader, :boolean, default: false)

    has_one(:guides_settings, GuidesSettings, on_replace: :update)

    belongs_to(:company, Api.Companies.Company)
  end

  def defaults do
    %__MODULE__{
      main_color: "#6E1DF4",
      secondary_color: "#3B67E9",
      disable_loader: false,
      guides_settings: GuidesSettings.defaults()
    }
  end

  def create_changeset(settings, attrs) do
    settings
    |> cast(attrs, [
      :company_id,
      :main_color,
      :secondary_color,
      :disable_loader
    ])
    |> cast_assoc(:guides_settings, with: &GuidesSettings.changeset/2)
    |> validate_required(:company_id)
    |> validate_required([:main_color, :secondary_color, :disable_loader, :guides_settings])
    |> unsafe_validate_unique([:company_id], Api.Repo,
      message: "can't have more than 1 settings per company"
    )
    |> validate_color_fields()
  end

  def update_changeset(settings, attrs) do
    settings
    |> cast(attrs, [
      :main_color,
      :secondary_color,
      :disable_loader
    ])
    |> cast_assoc(:guides_settings, with: &GuidesSettings.changeset/2)
    |> validate_required([:main_color, :secondary_color, :disable_loader])
    |> validate_color_fields()
  end

  defp validate_color_fields(changeset) do
    changeset
    |> validate_format(:main_color, hex_format_regex())
    |> validate_format(:secondary_color, hex_format_regex())
  end
end
