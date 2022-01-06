defmodule Api.Repo.Migrations.CreateStorylineGuidesSettings do
  use Ecto.Migration

  def change do
    create table(:storyline_guides_settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:show_glow, :boolean)
      add(:glow_color, :string)
      add(:background_color, :string)
      add(:font_color, :string)
      add(:font_size, :integer)
      add(:accent_color, :string)
      add(:smooth_scrolling, :boolean)
      add(:hide_dismiss, :boolean)
      add(:dim_by_default, :boolean)
      add(:celebrate_guides_completion, :boolean)

      add(
        :storyline_settings_id,
        references(:storyline_settings, type: :binary_id, on_delete: :delete_all),
        null: false
      )
    end
  end
end
