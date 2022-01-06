defmodule Api.Repo.Migrations.AddDisableLoader do
  use Ecto.Migration

  def change do
    alter table(:settings) do
      add(:disable_loader, :boolean, default: false, null: false)
    end
  end
end
