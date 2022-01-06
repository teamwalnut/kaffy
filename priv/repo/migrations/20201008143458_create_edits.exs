defmodule Api.Repo.Migrations.CreateEdits do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:edit_type, [:style, :text, :link, :change_image])

    create table(:edits, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:kind, :edit_type, null: false)

      add(:css_selector, :string, null: false)
      add(:text_edit_props, :map)
      add(:style_edit_props, :map)
      add(:link_edit_props, :map)
      add(:change_image_edit_props, :map)

      add(:screen_id, references(:screens, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    create(index(:edits, [:screen_id]))
  end
end
