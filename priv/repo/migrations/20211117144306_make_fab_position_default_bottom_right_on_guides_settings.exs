defmodule Api.Repo.Migrations.MakeFabPositionDefaultBottomRightOnGuidesSettings do
  use Ecto.Migration

  def up do
    alter table(:guides_settings) do
      modify(:fab, :map,
        default: Jason.encode!(%{"enabled" => false, "position" => "bottom_right"}),
        null: false
      )
    end
  end

  def down do
    alter table(:guides_settings) do
      modify(:fab, :map,
        default: Jason.encode!(%{"enabled" => false}),
        null: false
      )
    end
  end
end
