defmodule Api.Repo.Migrations.CreateScreens do
  use Ecto.Migration

  def change do
    create table(:screens, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:url, :string)
      add(:last_edited, :timestamptz, null: false, default: fragment("now()"))
      add(:serialized_dom, :string, null: false)
      add(:screenshot_image_uri, :string)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    alter table(:storylines) do
      add(:start_screen_id, references(:screens, on_delete: :nothing, type: :binary_id))
    end

    create(index(:screens, [:storyline_id]))
  end
end
