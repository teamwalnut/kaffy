defmodule Api.Repo.Migrations.IncreasingUrlLimit do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      modify(:url, :text)
    end
  end
end
