defmodule Api.Repo.Migrations.CreateFlowScreens do
  use Ecto.Migration

  def change do
    create table(:flow_screens, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:position, :integer)
      add(:flow_id, references(:flows, on_delete: :delete_all, type: :binary_id))
      add(:screen_id, references(:screens, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    create(unique_index(:flow_screens, [:screen_id]))
    create(unique_index(:flow_screens, [:position, :flow_id]))
  end
end
