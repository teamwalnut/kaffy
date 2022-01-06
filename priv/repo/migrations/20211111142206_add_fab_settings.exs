defmodule Api.Repo.Migrations.AddFabSettings do
  use Ecto.Migration

  def up do
    alter table(:guides_settings) do
      add(:fab, :map, default: Jason.encode!(%{"enabled" => false}), null: false)
    end

    alter table(:storyline_guides_settings) do
      add(:fab, :map, default: "{}", null: false)
    end
  end

  def down do
    alter table(:guides_settings) do
      remove(:fab, :map)
    end

    alter table(:storyline_guides_settings) do
      remove(:fab, :map)
    end
  end
end
