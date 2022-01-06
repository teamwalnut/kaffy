defmodule Api.Repo.Migrations.AddDomains do
  use Ecto.Migration

  def change do
    create table(:custom_domains, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:domain, :string, null: false)
      add(:env, :string, null: false)

      add(:company_id, references(:companies, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      timestamps()
    end

    create(unique_index(:custom_domains, [:domain, :company_id]))
  end
end
