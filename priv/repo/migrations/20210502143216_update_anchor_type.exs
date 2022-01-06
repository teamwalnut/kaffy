defmodule Api.Repo.Migrations.UpdateAnchorType do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE anchor_type ADD VALUE IF NOT EXISTS 'auto'")
  end

  def down do
    :ok
  end
end
