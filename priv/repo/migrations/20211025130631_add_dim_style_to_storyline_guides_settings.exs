defmodule Api.Repo.Migrations.AddDimStyleToStorylineGuidesSettings do
  use Ecto.Migration

  def change do
    alter table(:storyline_guides_settings) do
      add(:dim_style, :dim_type, null: true)
    end
  end
end
