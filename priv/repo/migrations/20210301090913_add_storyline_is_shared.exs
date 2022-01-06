defmodule Api.Repo.Migrations.AddStorylineIsShared do
  use Ecto.Migration

  def change do
    alter table(:storylines) do
      add(:is_shared, :boolean, default: false, null: false)
    end
  end
end
