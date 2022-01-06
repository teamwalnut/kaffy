defmodule Api.Repo.Migrations.AddScrollEdit do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    EctoEnumMigration.add_value_to_type(:edit_type, :scroll)

    alter table(:edits) do
      add(:scroll_edit_props, :map)
    end
  end
end
