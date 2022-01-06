defmodule Api.Repo.Migrations.AddUniqueIndexesToSettings do
  use Ecto.Migration

  def change do
    create(unique_index(:company_settings, [:company_id]))
    create(unique_index(:storyline_settings, [:storyline_id]))
    create(unique_index(:guides_settings, [:company_settings_id]))
    create(unique_index(:guides_settings, [:demo_version_settings_id]))
    create(unique_index(:storyline_guides_settings, [:storyline_settings_id]))
  end
end
