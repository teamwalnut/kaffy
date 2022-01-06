defmodule Api.Repo.Migrations.MakeCompanySettingsNonNull do
  use Ecto.Migration

  def change do
    alter table("company_settings") do
      modify(:main_color, :string, null: false, default: "#6E1DF4")
      modify(:secondary_color, :string, null: false, default: "#3B67E9")
      modify(:disable_loader, :boolean, null: false, default: false)
    end
  end
end
