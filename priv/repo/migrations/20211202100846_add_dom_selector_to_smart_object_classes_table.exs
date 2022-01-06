defmodule Api.Repo.Migrations.AddDomSelectorToSmartObjectClassesTable do
  use Ecto.Migration

  def change do
    alter table(:smart_object_classes) do
      add(:dom_selector, :map, null: true)
    end
  end
end
