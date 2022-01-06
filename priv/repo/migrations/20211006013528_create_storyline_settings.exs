defmodule Api.Repo.Migrations.CreateStorylineSettings do
  use Ecto.Migration

  def change do
    create table(:storyline_settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:global_js, :string)
      add(:global_css, :string)
      add(:main_color, :string)
      add(:secondary_color, :string)
      add(:disable_loader, :boolean)

      add(:storyline_id, references(:storylines, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end
  end
end
