defmodule Api.Repo.Migrations.CreateStorylines do
  use Ecto.Migration

  def change do
    create table(:storylines, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:last_edited, :timestamptz, null: false, default: fragment("now()"))
      add(:owner_id, references(:members, on_delete: :delete_all, type: :binary_id), null: false)
      add(:is_public, :boolean, default: false, null: false)

      timestamps()
    end
  end
end
