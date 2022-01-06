defmodule Api.Repo.Migrations.AddManifestToScreen do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      add(:asset_manifest, :map, default: "{}", null: false)
    end
  end
end
