defmodule Api.Repo.Migrations.ChangeMemberRoleFieldToEnum do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:member_role, [:company_admin, :presenter])

    alter table(:members) do
      remove(:role, :string)
    end

    alter table(:members) do
      add(:role, :member_role, default: "company_admin")
    end
  end
end
