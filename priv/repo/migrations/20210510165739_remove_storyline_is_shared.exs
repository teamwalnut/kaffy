defmodule Api.Repo.Migrations.RemoveStorylineIsShared do
  use Ecto.Migration

  def up do
    alter table(:storylines) do
      remove(:is_shared)
    end
  end

  def down do
    alter table(:storylines) do
      add(:is_shared, :boolean, default: true, null: false)
    end
  end
end
