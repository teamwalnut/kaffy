defmodule Api.Repo.Migrations.CreateGuidesSettings do
  use Ecto.Migration

  def change do
    create table(:guides_settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:show_glow, :boolean, null: false)
      add(:glow_color, :string, null: false)
      add(:background_color, :string, null: false)
      add(:font_color, :string, null: false)
      add(:font_size, :integer, null: false)
      add(:accent_color, :string, null: false)
      add(:smooth_scrolling, :boolean, null: false)
      add(:hide_dismiss, :boolean, null: false)
      add(:dim_by_default, :boolean, null: false)
      add(:celebrate_guides_completion, :boolean, null: false)

      add(
        :company_settings_id,
        references(:company_settings, type: :binary_id, on_delete: :delete_all)
      )

      add(
        :demo_version_settings_id,
        references(:demo_version_settings, type: :binary_id, on_delete: :delete_all)
      )
    end
  end
end
