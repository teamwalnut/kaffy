defmodule Api.Repo.Migrations.AddDemoVersionIdToStorylineSettings do
  use Ecto.Migration

  def up do
    alter table(:settings) do
      add(:demo_version_id, references(:demo_versions, on_delete: :delete_all, type: :binary_id))
    end

    drop(index(:settings, [:storyline_id]))
    create(unique_index(:settings, [:storyline_id]))
    create(unique_index(:settings, [:demo_version_id]))
  end

  def down do
    drop(index(:settings, [:storyline_id]))
    drop(index(:settings, [:demo_version_id]))
    create(index(:settings, [:storyline_id]))

    alter table(:settings) do
      remove(
        :demo_version_id,
        references(:demo_versions, on_delete: :delete_all, type: :binary_id)
      )
    end
  end
end
