defmodule Api.Repo.Migrations.AddAssetsCache do
  use Ecto.Migration

  def change do
    create table(:assets, primary_key: false) do
      add(:name, :text, null: false)
      timestamps()
    end

    create(unique_index(:assets, [:name], name: :assets_name_index))
  end
end
