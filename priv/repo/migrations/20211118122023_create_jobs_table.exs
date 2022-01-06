defmodule Api.Repo.Migrations.CreateJobsTable do
  use Ecto.Migration

  def change do
    create table(:jobs, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:job_name, :text)
      add(:status, :text)

      timestamps()
    end
  end
end
