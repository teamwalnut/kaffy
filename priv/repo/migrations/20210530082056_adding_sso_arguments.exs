defmodule Api.Repo.Migrations.AddingSsoArguments do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:sso_strategy, [:oidc])

    alter table(:companies) do
      add(:domain, :string)
      add(:sso_strategy, :sso_strategy)
      add(:sso_only, :boolean, default: false, null: false)
      add(:oidc, :map)
    end
  end
end
