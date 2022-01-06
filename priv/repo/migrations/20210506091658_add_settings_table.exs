defmodule Api.Repo.Migrations.AddSettingsTable do
  use Ecto.Migration

  def change do
    create table(:settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:global_js, :string)
      add(:global_css, :string)
      add(:main_color, :string)
      add(:secondary_color, :string)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))
      timestamps()
    end

    create(index(:settings, [:storyline_id]))
  end
end
