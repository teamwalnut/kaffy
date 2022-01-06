defmodule Api.Repo.Migrations.CreatePatches do
  use Ecto.Migration

  def change do
    create table(:patches, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:data, :map, default: "{}", null: false)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))
      add(:company_id, references(:companies, on_delete: :delete_all, type: :binary_id))

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:patches, [:storyline_id]))
    create(index(:patches, [:company_id]))
  end
end
