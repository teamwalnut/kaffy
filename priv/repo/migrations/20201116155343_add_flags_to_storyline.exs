defmodule Api.Repo.Migrations.AddFlagsToStoryline do
  use Ecto.Migration

  def change do
    alter table(:storylines) do
      # Flags related to demo playback
      add(:demo_flags, :map, default: "{}", null: false)
    end
  end
end
