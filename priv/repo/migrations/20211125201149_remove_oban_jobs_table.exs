defmodule Api.Repo.Migrations.RemoveObanJobsTable do
  use Ecto.Migration

  def change do
    drop_if_exists(table("oban_jobs"))
  end
end
