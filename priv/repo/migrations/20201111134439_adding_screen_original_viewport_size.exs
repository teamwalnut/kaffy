defmodule Api.Repo.Migrations.AddingScreenOriginalViewportSize do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      add(:original_dimensions, :map)
    end
  end
end
