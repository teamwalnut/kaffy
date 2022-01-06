defmodule Api.Repo.Migrations.AddFlowIdIndex do
  use Ecto.Migration

  def change do
    create(index(:flow_screens, [:flow_id]))
  end
end
