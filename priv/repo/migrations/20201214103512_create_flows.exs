defmodule Api.Repo.Migrations.CreateFlows do
  use Ecto.Migration

  def change do
    create table(:flows, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:is_default, :boolean, default: false)
      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id))

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:flows, [:storyline_id]))

    create(
      unique_index(:flows, [:is_default, :storyline_id],
        name: :one_default_per_storyline_index,
        where: "is_default = true"
      )
    )
  end
end
