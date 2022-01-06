defmodule Api.Repo.Migrations.CreateDemos do
  use Ecto.Migration

  def change do
    create table(:demos, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))
      timestamps()
    end

    create(index(:demos, [:storyline_id]))
  end
end
