defmodule Api.Repo.Migrations.AddSmartObjectInstancesToScreenTable do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      add(:smart_object_instances, :map, null: true)
    end
  end
end
