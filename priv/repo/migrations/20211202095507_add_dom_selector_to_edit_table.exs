defmodule Api.Repo.Migrations.AddDomSelectorToEditTable do
  use Ecto.Migration

  def change do
    alter table(:edits) do
      add(:dom_selector, :map, null: true)
    end
  end
end
