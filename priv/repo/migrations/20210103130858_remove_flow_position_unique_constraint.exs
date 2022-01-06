defmodule Api.Repo.Migrations.RemoveFlowPositionUniqueConstraint do
  use Ecto.Migration

  def up do
    drop(index(:flows, [:position, :storyline_id]))

    execute(
      "alter table flows add constraint flows_position_storyline_id unique(position, storyline_id) deferrable initially immediate;"
    )
  end

  def down do
    create(unique_index(:flows, [:position, :storyline_id]))
    execute("alter table flows drop constraint flows_position_storyline_id")
  end
end
