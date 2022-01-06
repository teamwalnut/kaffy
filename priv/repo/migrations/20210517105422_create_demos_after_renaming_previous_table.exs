defmodule Api.Repo.Migrations.CreateDemosAfterRenamingPreviousTable do
  use Ecto.Migration

  def change do
    create table(:demos, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:is_shared, :boolean, default: true, null: false)
      add(:last_played, :utc_datetime_usec)
      add(:active_version_id, references(:demo_versions, type: :binary_id))
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    alter table(:demo_versions) do
      add(:demo_id, references(:demos, on_delete: :delete_all, type: :binary_id))
    end

    create(unique_index(:demos, [:active_version_id]))
  end
end
