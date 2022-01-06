defmodule Api.Repo.Migrations.AddGuidesSettingsToStorylineSettings do
  use Ecto.Migration

  def up do
    alter table(:settings) do
      add(:guides_settings, :map, null: false, default: %{})
    end
  end

  def down do
    alter table(:settings) do
      remove(:guides_settings, :map, null: false)
    end
  end
end
