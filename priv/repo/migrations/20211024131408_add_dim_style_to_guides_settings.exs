defmodule Api.Repo.Migrations.AddDimStyleToGuidesSettings do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:dim_type, [:soft, :medium, :dark])

    alter table(:guides_settings) do
      add(:dim_style, :dim_type, null: false, default: "medium")
    end
  end
end
