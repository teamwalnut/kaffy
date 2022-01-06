defmodule Api.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:role, :string, null: true)
      add(:user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false)

      add(:company_id, references(:companies, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      timestamps()
    end

    create(
      unique_index(:members, [:user_id, :company_id], name: :members_user_id_company_id_index)
    )
  end
end
