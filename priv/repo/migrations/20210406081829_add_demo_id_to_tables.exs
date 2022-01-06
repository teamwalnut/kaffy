defmodule Api.Repo.Migrations.AddDemoIdToTables do
  use Ecto.Migration

  def change do
    alter table(:flows) do
      add(:demo_id, references(:demos, on_delete: :nothing, type: :binary_id))
    end

    alter table(:guides) do
      add(:demo_id, references(:demos, on_delete: :nothing, type: :binary_id))
    end

    alter table(:patches) do
      add(:demo_id, references(:demos, on_delete: :nothing, type: :binary_id))
    end

    alter table(:demos) do
      add(:start_screen_id, references(:screens, on_delete: :nothing, type: :binary_id))
      add(:last_played, :utc_datetime_usec)

      add(:created_by_id, references(:members, on_delete: :nothing, type: :binary_id), null: false)
    end

    create(unique_index(:demos, [:storyline_id, :name]))
  end
end
