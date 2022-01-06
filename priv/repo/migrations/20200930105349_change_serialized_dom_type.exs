defmodule Api.Repo.Migrations.ChangeSerializedDomType do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      modify(:serialized_dom, :text)
      modify(:screenshot_image_uri, :text)
    end
  end
end
