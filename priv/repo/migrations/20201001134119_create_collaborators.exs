defmodule Api.Repo.Migrations.CreateCollaborators do
  use Ecto.Migration

  def change do
    create table(:storylines_collaborators, primary_key: false) do
      add(:member_id, references(:members, on_delete: :delete_all, type: :binary_id), null: false)

      add(:storyline_id, references(:storylines, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      timestamps()
    end

    create(
      unique_index(:storylines_collaborators, [:storyline_id, :member_id],
        name: :storylines_collaborators_storyline_id_member_id_index
      )
    )
  end
end
