defmodule Api.Repo.Migrations.AddPositionToFlow do
  use Ecto.Migration

  def change do
    alter table(:flows) do
      add(:position, :integer, null: false)
    end

    create(unique_index(:flows, [:position, :storyline_id]))

    alter table(:flow_screens) do
      modify(:position, :integer, null: false)
    end
  end
end
