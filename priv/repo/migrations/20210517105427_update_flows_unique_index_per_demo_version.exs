defmodule Api.Repo.Migrations.UpdateFlowsUniqueIndexPerDemoVersion do
  use Ecto.Migration

  def up do
    execute("drop index if exists one_default_per_storyline_or_demo_index")

    create(
      unique_index(:flows, [:is_default, :storyline_id, :demo_version_id],
        name: :one_default_per_storyline_or_demo_version_index,
        where: "is_default = true"
      )
    )
  end

  def down do
    execute("drop index if exists one_default_per_storyline_or_demo_version_index")

    create(
      unique_index(:flows, [:is_default, :storyline_id],
        name: :one_default_per_storyline_or_demo_index,
        where: "is_default = true"
      )
    )
  end
end
