defmodule Api.Repo.Migrations.ReplaceDemosWithDemoVersions do
  use Ecto.Migration

  def up do
    execute("alter table flows drop if exists demo_id")

    execute("alter table guides drop if exists demo_id")

    execute("alter table patches drop if exists demo_id")

    execute("drop table if exists demos cascade")

    create table(:demo_versions, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:start_screen_id, references(:screens, on_delete: :nothing, type: :binary_id))

      add(:created_by_id, references(:members, on_delete: :nothing, type: :binary_id), null: false)

      timestamps()
    end

    alter table(:flows) do
      add(:demo_version_id, references(:demo_versions, on_delete: :delete_all, type: :binary_id))
    end

    alter table(:guides) do
      add(:demo_version_id, references(:demo_versions, on_delete: :delete_all, type: :binary_id))
    end

    alter table(:patches) do
      add(:demo_version_id, references(:demo_versions, on_delete: :delete_all, type: :binary_id))
    end
  end

  def down do
    alter table(:flows) do
      remove(:demo_version_id, references(:demo_versions, type: :binary_id))
    end

    alter table(:guides) do
      remove(:demo_version_id, references(:demo_versions, type: :binary_id))
    end

    alter table(:patches) do
      remove(:demo_version_id, references(:demo_versions, type: :binary_id))
    end

    execute("drop table if exists demo_versions cascade")

    create table(:demos, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))
      timestamps()
    end

    create(index(:demos, [:storyline_id]))

    alter table(:flows) do
      add(:demo_id, references(:demos, on_delete: :nothing, type: :binary_id))
    end

    alter table(:guides) do
      add(:demo_id, references(:demos, on_delete: :nothing, type: :binary_id))
    end

    alter table(:patches) do
      add(:demo_id, references(:demos, on_delete: :nothing, type: :binary_id))
    end
  end
end
