defmodule Api.Repo.Migrations.AddShowAvatarAndAvatarUrlToGuidesSettings do
  use Ecto.Migration

  def up do
    alter table(:guides_settings) do
      add(:show_avatar, :boolean, default: false, null: false)
      add(:avatar_url, :text)
    end

    alter table(:storyline_guides_settings) do
      add(:show_avatar, :boolean)
      add(:avatar_url, :text)
    end
  end

  def down do
    alter table(:guides_settings) do
      remove(:show_avatar, :boolean, default: false, null: false)
      remove(:avatar_url, :text)
    end

    alter table(:storyline_guides_settings) do
      remove(:show_avatar, :boolean)
      remove(:avatar_url, :text)
    end
  end
end
