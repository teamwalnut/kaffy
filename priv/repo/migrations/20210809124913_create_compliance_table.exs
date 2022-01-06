defmodule Api.Repo.Migrations.CreateComplianceTable do
  use Ecto.Migration

  def change do
    create table(:compliances, primary_key: false) do
      add(:user_id, references(:users, on_delete: :delete_all, type: :binary_id),
        null: false,
        primary_key: true
      )

      add(:tac_approved_at, :utc_datetime_usec, null: false)
      timestamps()
    end
  end
end
