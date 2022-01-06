defmodule Api.Repo.Migrations.AddShowMainButtonAndMainButtonTextToGuidesSettings do
  use Ecto.Migration

  def up do
    alter table(:guides_settings) do
      add(:show_main_button, :boolean, default: true, null: false)
      add(:main_button_text, :string, default: "Next", null: false)
    end

    alter table(:storyline_guides_settings) do
      add(:show_main_button, :boolean)
      add(:main_button_text, :string)
    end
  end

  def down do
    alter table(:guides_settings) do
      remove(:show_main_button, :boolean, default: true, null: false)
      remove(:main_button_text, :string, default: "Next", null: false)
    end

    alter table(:storyline_guides_settings) do
      remove(:show_main_button, :boolean)
      remove(:main_button_text, :string)
    end
  end
end
