defmodule Api.Repo.Migrations.AddingArchivedAt do
  use Ecto.Migration

  def change do
    alter table(:storylines) do
      add(:archived_at, :timestamptz)
    end

    create(index(:storylines, [:archived_at]))
  end
end
