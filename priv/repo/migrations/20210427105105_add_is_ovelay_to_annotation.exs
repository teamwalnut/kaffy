defmodule Api.Repo.Migrations.AddIsOvelayToAnnotation do
  use Ecto.Migration

  def change do
    alter table(:annotations) do
      add(:has_overlay, :boolean, default: false, null: false)
    end
  end
end
