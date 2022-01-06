defmodule Api.Repo.Migrations.AddBindingEditPropsToEdits do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    EctoEnumMigration.add_value_to_type(:edit_type, :binding)

    alter table(:edits) do
      add(:binding_edit_props, :map)
    end
  end
end
