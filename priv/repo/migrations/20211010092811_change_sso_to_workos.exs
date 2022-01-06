defmodule Api.Repo.Migrations.ChangeSsoToWorkos do
  use Ecto.Migration
  import EctoEnumMigration

  def up do
    alter table(:companies) do
      remove(:sso_strategy)
      remove(:sso_only)
      remove(:oidc)
      remove(:domain)
    end

    create table(:company_sso) do
      add(:company_id, references(:companies, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:workos_org_id, :string, null: false)
      add(:workos_conn_id, :string, null: false)
      add(:domain, :string, null: false)
      timestamps()
    end

    drop_type(:sso_strategy)
    create(unique_index(:company_sso, [:workos_org_id]))
    create(unique_index(:company_sso, [:workos_conn_id]))
    create(unique_index(:company_sso, [:company_id]))
    create(unique_index(:company_sso, ["lower(domain)"], name: :domain_index))
  end

  def down do
    create_type(:sso_strategy, [:oidc])

    alter table(:companies) do
      add(:sso_strategy, :sso_strategy)
      add(:sso_only, :boolean, default: false, null: false)
      add(:oidc, :map)
      add(:domain, :string)
    end

    drop(table(:company_sso))
    create(index(:companies, ["lower(domain)"], name: :domain_index, unique: true))
  end
end
