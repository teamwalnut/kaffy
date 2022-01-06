defmodule Api.Repo.Migrations.FixPostgresTypesOfDemoVersionSettings do
  use Ecto.Migration

  def change do
    alter table(:demo_version_settings) do
      modify(:global_css, :text)
      modify(:global_js, :text)
    end
  end
end
