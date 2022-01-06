defmodule Api.Repo.Migrations.AddIsPayingToCompany do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add(:is_paying, :boolean, default: false, null: false)
    end
  end
end
