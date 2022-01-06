defmodule Api.Repo.Migrations.AddPatchNameField do
  use Ecto.Migration

  def change do
    alter table(:patches) do
      add(:name, :string, null: false, default: "untitled")
    end
  end
end
