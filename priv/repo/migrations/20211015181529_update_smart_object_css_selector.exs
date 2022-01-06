defmodule Api.Repo.Migrations.UpdateSmartObjectCssSelector do
  use Ecto.Migration

  def up do
    alter table(:smart_object_classes) do
      modify(:css_selector, :text, null: false)
    end
  end

  def down do
    alter table(:smart_object_classes) do
      modify(:css_selector, :string, null: false)
    end
  end
end
