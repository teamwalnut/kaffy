defmodule Api.Repo.Migrations.RemoveUniqueConstaintForFlowScreenPosition do
  use Ecto.Migration

  def up do
    drop(index(:flow_screens, [:position, :flow_id]))

    execute(
      "alter table flow_screens add constraint flow_screens_position_flow_id unique(position, flow_id) deferrable initially immediate;"
    )
  end

  def down do
    create(unique_index(:flow_screens, [:position, :flow_id]))
    execute("alter table flow_screens drop constraint flow_screens_position_flow_id")
  end
end
