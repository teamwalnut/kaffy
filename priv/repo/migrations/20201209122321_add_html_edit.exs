defmodule Api.Repo.Migrations.AddHtmlEdit do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    EctoEnumMigration.add_value_to_type(:edit_type, :html)

    alter table(:edits) do
      add(:html_edit_props, :map)
    end
  end
end
