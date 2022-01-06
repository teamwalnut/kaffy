defmodule Api.Repo.Migrations.ChangeLastEditedDefault do
  use Ecto.Migration

  def up do
    alter table(:screens) do
      modify(:last_edited, :timestamptz, null: false, default: fragment("now()"))
    end
  end

  def down do
    # theoretically, it should already be at the needed state
    :ok
  end
end
