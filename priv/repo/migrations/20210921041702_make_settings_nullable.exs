defmodule Api.Repo.Migrations.MakeSettingsNullable do
  use Ecto.Migration

  def change do
    alter table(:settings) do
      modify(:main_color, :string, default: nil, null: true)
      modify(:secondary_color, :string, default: nil, null: true)
      modify(:disable_loader, :boolean, default: nil, null: true)
    end
  end
end
