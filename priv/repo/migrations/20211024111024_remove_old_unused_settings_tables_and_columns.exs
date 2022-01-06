defmodule Api.Repo.Migrations.RemoveOldUnusedSettingsTablesAndColumns do
  use Ecto.Migration

  def up do
    drop(table(:settings))

    alter table(:company_settings) do
      remove(:guides_settings)
    end
  end

  def down do
    create table(:settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:global_js, :text)
      add(:global_css, :text)
      add(:main_color, :string)
      add(:secondary_color, :string)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))
      add(:demo_version_id, references(:demo_versions, on_delete: :delete_all, type: :binary_id))
      add(:guides_settings, :map, null: false, default: %{})
      add(:disable_loader, :boolean)
      timestamps()
    end

    create(unique_index(:settings, [:storyline_id]))
    create(unique_index(:settings, [:demo_version_id]))

    alter table(:company_settings) do
      add(:guides_settings, :map, null: false, default: %{})
    end
  end
end
