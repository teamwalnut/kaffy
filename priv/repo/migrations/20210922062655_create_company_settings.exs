defmodule Api.Repo.Migrations.CreateCompanySettings do
  use Ecto.Migration

  def change do
    create table(:company_settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:main_color, :string)
      add(:secondary_color, :string)
      add(:disable_loader, :boolean)
      add(:guides_settings, :map, null: false, default: %{})

      add(:company_id, references(:companies, on_delete: :delete_all, type: :binary_id),
        null: false
      )
    end
  end
end
