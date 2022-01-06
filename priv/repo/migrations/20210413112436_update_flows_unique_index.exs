defmodule Api.Repo.Migrations.UpdateFlowsUniqueIndex do
  use Ecto.Migration

  def up do
    execute("drop index if exists one_default_per_storyline_index")

    create(
      unique_index(:flows, [:is_default, :storyline_id, :demo_id],
        name: :one_default_per_storyline_or_demo_index,
        where: "is_default = true"
      )
    )
  end

  def down do
    execute("drop index if exists one_default_per_storyline_or_demo_index")

    create(
      unique_index(:flows, [:is_default, :storyline_id],
        name: :one_default_per_storyline_index,
        where: "is_default = true"
      )
    )
  end
end
