defmodule Api.Repo.Migrations.MakeCompanyDomainUnique do
  use Ecto.Migration

  def change do
    create(index(:companies, ["lower(domain)"], name: :domain_index, unique: true))
  end
end
