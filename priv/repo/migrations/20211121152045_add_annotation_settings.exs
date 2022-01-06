defmodule Api.Repo.Migrations.AddAnnotationSettings do
  use Ecto.Migration

  def change do
    alter table(:annotations) do
      add(:settings, :map, default: "{}", null: false)
    end
  end
end
