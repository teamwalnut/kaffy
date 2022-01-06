defmodule Api.Repo.Migrations.AddLockedCompanyFlag do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add(:is_locked, :boolean, default: false, null: false)
    end
  end
end
