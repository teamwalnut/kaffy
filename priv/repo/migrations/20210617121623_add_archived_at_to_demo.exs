defmodule Api.Repo.Migrations.AddArchivedAtToDemo do
  use Ecto.Migration

  def change do
    alter table(:demos) do
      add(:archived_at, :timestamptz)
    end

    create(index(:demos, [:archived_at]))
  end
end
