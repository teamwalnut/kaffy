defmodule Api.Repo.Migrations.RemoveHasOverlayFromAnnotations do
  use Ecto.Migration

  def up do
    alter table(:annotations) do
      remove(:has_overlay)
    end
  end

  def down do
    alter table(:annotations) do
      add(:has_overlay, :boolean, default: false, null: false)
    end
  end
end
