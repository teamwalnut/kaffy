defmodule Api.Repo.Migrations.AddExtraRolesToMemberRoleType do
  use Ecto.Migration
  import EctoEnumMigration
  @disable_ddl_transaction true

  def up do
    add_value_to_type(:member_role, :editor)
    add_value_to_type(:member_role, :viewer)
  end
end
