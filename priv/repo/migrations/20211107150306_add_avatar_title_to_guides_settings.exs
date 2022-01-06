defmodule Api.Repo.Migrations.AddAvatarTitleToGuidesSettings do
  use Ecto.Migration

  def up do
    alter table(:guides_settings) do
      add(:avatar_title, :string)
    end

    alter table(:storyline_guides_settings) do
      add(:avatar_title, :string)
    end
  end

  def down do
    alter table(:guides_settings) do
      remove(:avatar_title, :string)
    end

    alter table(:storyline_guides_settings) do
      remove(:avatar_title, :string)
    end
  end
end
