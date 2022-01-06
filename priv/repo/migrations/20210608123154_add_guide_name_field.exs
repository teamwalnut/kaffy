defmodule Api.Repo.Migrations.AddGuideNameField do
  use Ecto.Migration

  def change do
    alter table(:guides) do
      add(:name, :string, null: false, default: "Guide 1")
    end
  end
end
