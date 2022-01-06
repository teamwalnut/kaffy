defmodule Api.Repo.Migrations.ChangeMainColorAndSecondaryColorDefaults do
  use Ecto.Migration

  def up do
    alter table(:settings) do
      modify(:main_color, :string, default: "#6E1DF4", null: false)
      modify(:secondary_color, :string, default: "#3B67E9", null: false)
    end
  end

  def down do
    alter table(:settings) do
      modify(:main_color, :string, default: nil, null: true)
      modify(:secondary_color, :string, default: nil, null: true)
    end
  end
end
