defmodule Api.Repo.Migrations.ChangeMemberInviteExpiresAtToUtcDatetime do
  use Ecto.Migration

  def change do
    alter table(:member_invites) do
      modify(:expires_at, :timestamptz)
    end
  end
end
