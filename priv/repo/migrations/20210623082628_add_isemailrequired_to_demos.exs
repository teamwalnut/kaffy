defmodule Api.Repo.Migrations.AddIsemailrequiredToDemos do
  use Ecto.Migration

  def change do
    alter table(:demos) do
      add(:email_required, :bool, default: false)
    end
  end
end
