defmodule Api.Repo.Migrations.AddLastEditedAtToEdit do
  use Ecto.Migration

  def up do
    alter table(:edits) do
      add(:last_edited_at, :timestamptz, null: false, default: fragment("now()"))
    end
  end

  def down do
    alter table(:edits) do
      remove(:last_edited_at, :timestamptz, null: false, default: fragment("now()"))
    end
  end
end
