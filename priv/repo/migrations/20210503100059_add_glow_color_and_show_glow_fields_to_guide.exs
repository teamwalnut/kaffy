defmodule Api.Repo.Migrations.AddGlowColorAndShowGlowFieldsToGuide do
  use Ecto.Migration

  def change do
    alter table(:guides) do
      add(:glow_color, :string, default: "#3b85e948", null: false)
      add(:show_glow, :boolean, default: true, null: false)
    end
  end
end
