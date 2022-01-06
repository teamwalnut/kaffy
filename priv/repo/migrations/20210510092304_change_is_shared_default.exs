defmodule Api.Repo.Migrations.ChangeIsSharedDefault do
  use Ecto.Migration

  def up do
    alter table(:storylines) do
      modify(:is_shared, :boolean, default: true, null: false)
    end
  end

  def down do
    alter table(:storylines) do
      modify(:is_shared, :boolean, default: false, null: false)
    end
  end
end
