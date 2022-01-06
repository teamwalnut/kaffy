defmodule Api.Repo.Migrations.AddPriorityToGuide do
  use Ecto.Migration

  def up do
    alter table(:guides) do
      add(:priority, :integer, null: false, default: 0)
    end

    execute(
      "alter table guides add constraint guides_priority_storyline_id_demo_version_id unique(priority, storyline_id, demo_version_id) deferrable initially immediate;"
    )
  end

  def down do
    alter table(:guides) do
      remove(:priority, :integer, null: false, default: 0)
    end
  end
end
