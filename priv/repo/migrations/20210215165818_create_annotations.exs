defmodule Api.Repo.Migrations.CreateAnnotations do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:annotation_kind, [:point, :modal])
    create_type(:anchor_type, [:top, :right, :bottom, :left])

    create table(:annotations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:kind, :annotation_kind, null: false)
      add(:message, :string, null: false)
      add(:step, :integer, null: false)
      add(:css_selector, :string)
      add(:frame_selectors, {:array, :string})
      add(:anchor, :anchor_type)
      add(:guide_id, references(:guides, on_delete: :delete_all, type: :binary_id), null: false)
      add(:screen_id, references(:screens, on_delete: :delete_all, type: :binary_id), null: false)

      timestamps()
    end

    create(index(:annotations, [:screen_id]))
    create(index(:annotations, [:guide_id]))
  end
end
