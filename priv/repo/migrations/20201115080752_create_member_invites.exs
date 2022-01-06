defmodule Api.Repo.Migrations.CreateMemberInvites do
  use Ecto.Migration

  def change do
    create table(:member_invites, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:email, :citext, null: false)
      add(:token, :binary, null: false)
      add(:expires_at, :naive_datetime, null: false)

      add(:company_id, references(:companies, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:member_id, references(:members, on_delete: :delete_all, type: :binary_id), null: true)

      timestamps()
    end

    create(
      unique_index(:member_invites, [:email, :company_id],
        name: :member_invites_email_company_id_index
      )
    )

    create(unique_index(:member_invites, [:token]))
  end
end
