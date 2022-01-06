defmodule Api.Repo.Migrations.FixPostgresTypesOfStorylineSettings do
  use Ecto.Migration

  def change do
    alter table(:storyline_settings) do
      modify(:global_css, :text)
      modify(:global_js, :text)
    end
  end
end
