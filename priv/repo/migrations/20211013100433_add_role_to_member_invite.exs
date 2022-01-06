defmodule Api.Repo.Migrations.AddRoleToMemberInvite do
  use Ecto.Migration

  def change do
    alter table(:member_invites) do
      add(:role, :member_role, null: false, default: "company_admin")
    end
  end
end
