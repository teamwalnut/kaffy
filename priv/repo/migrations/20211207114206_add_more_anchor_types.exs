defmodule Api.Repo.Migrations.AddMoreAnchorTypes do
  use Ecto.Migration

  # note(paz): Altering enum type must be done outside of a transaction block. Reference: https://github.com/gjaldon/ecto_enum#postgres
  @disable_ddl_transaction true

  def up do
    Ecto.Migration.execute("ALTER TYPE anchor_type ADD VALUE IF NOT EXISTS 'top_start'")
    Ecto.Migration.execute("ALTER TYPE anchor_type ADD VALUE IF NOT EXISTS 'top_end'")
    Ecto.Migration.execute("ALTER TYPE anchor_type ADD VALUE IF NOT EXISTS 'bottom_start'")
    Ecto.Migration.execute("ALTER TYPE anchor_type ADD VALUE IF NOT EXISTS 'bottom_end'")
  end

  def down do
    # note(paz:) There is no way to drop an enum value from a type. The only way to do that is to create a new type and drop the old type.
    # This type of migration will be create (if needed) as a manual_migration and not as a regular migration.
    # So this migration is not reversiable.
    # Reference: https://www.postgresql.org/docs/current/datatype-enum.html
    :ok
  end
end
