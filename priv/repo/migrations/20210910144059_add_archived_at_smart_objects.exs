defmodule Api.Repo.Migrations.AddArchivedAtSmartObjects do
  use Ecto.Migration

  def change do
    alter table(:smart_object_classes) do
      add(:archived_at, :timestamptz)
    end

    create(index(:smart_object_classes, [:archived_at]))
  end
end
