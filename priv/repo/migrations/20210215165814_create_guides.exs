defmodule Api.Repo.Migrations.CreateGuides do
  use Ecto.Migration

  def change do
    create table(:guides, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    create(index(:guides, [:storyline_id]))
    create(unique_index(:guides, [:storyline_id, :id]))
  end
end
