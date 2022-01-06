defmodule Api.Repo.Migrations.AddAvailableDimensionsToScreen do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      add(:available_dimensions, :map)
    end
  end
end
