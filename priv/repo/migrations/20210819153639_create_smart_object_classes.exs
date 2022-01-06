defmodule Api.Repo.Migrations.CreateSmartObjectClasses do
  use Ecto.Migration

  def change do
    create table(:smart_object_classes, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:storyline_id, :binary_id)
      add(:name, :string, null: false)
      add(:thumbnail, :text)
      add(:edits, {:array, :map})
      add(:css_selector, :string, null: false)
      add(:frame_selectors, {:array, :string}, default: [])

      timestamps()
    end

    create(
      index(:smart_object_classes, ["storyline_id"], name: :storyline_id_index, unique: false)
    )
  end
end
