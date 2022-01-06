defmodule Api.Repo.Migrations.DemoVersionSettings do
  use Ecto.Migration

  def change do
    create table(:demo_version_settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:global_js, :string)
      add(:global_css, :string)
      add(:main_color, :string, null: false)
      add(:secondary_color, :string, null: false)
      add(:disable_loader, :boolean, null: false)

      add(:demo_version_id, references(:demo_versions, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end
  end
end
