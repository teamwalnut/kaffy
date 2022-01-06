defmodule Api.Repo.Migrations.AddVariable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:kind, [:text, :image])

    create table(:variables, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:description, :string, null: false)
      add(:kind, :kind, null: false)
      add(:default_value, :string, null: false)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    create(unique_index(:variables, [:storyline_id, :name]))
  end
end
