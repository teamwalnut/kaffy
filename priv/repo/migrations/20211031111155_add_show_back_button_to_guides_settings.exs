defmodule Api.Repo.Migrations.AddShowBackButtonToGuidesSettings do
  use Ecto.Migration

  def up do
    alter table(:guides_settings) do
      add(:show_back_button, :boolean, default: true, null: false)
    end

    alter table(:storyline_guides_settings) do
      add(:show_back_button, :boolean)
    end
  end

  def down do
    alter table(:guides_settings) do
      remove(:show_back_button, :boolean, default: true, null: false)
    end

    alter table(:storyline_guides_settings) do
      remove(:show_back_button, :boolean)
    end
  end
end
