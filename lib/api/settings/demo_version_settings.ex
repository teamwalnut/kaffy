defmodule Api.Settings.DemoVersionSettings do
  @moduledoc """
  Settings for the demo version
  """
  use Api.Schema

  # NOTE(Jaap): when you add a new field, make sure the field is non-null in the migration
  schema "demo_version_settings" do
    field(:global_js, :string)
    field(:global_css, :string)
    field(:main_color, :string)
    field(:secondary_color, :string)
    field(:disable_loader, :boolean)

    belongs_to(:demo_version, Api.Storylines.Demos.DemoVersion)
    has_one(:guides_settings, Api.Settings.GuidesSettings, on_replace: :update)

    timestamps()
  end
end
