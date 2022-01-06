defmodule Api.Repo.Migrations.AddingS3UriToScreen do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      remove(:serialized_dom)
      add(:s3_object_name, :text, null: false)
    end
  end
end
