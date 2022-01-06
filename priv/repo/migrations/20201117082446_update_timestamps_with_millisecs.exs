defmodule Api.Repo.Migrations.UpdateTimestampsWithMillisecs do
  use Ecto.Migration

  @tables ~w/users storylines_collaborators screens members edits storylines companies assets/
  def up do
    alter table(:users_tokens) do
      modify(:inserted_at, :utc_datetime_usec)
    end

    # For each of the listed tables, change the type of :inserted_at and :updated_at to microsecond precision
    @tables
    |> Enum.map(&String.to_atom/1)
    |> Enum.each(fn table_name ->
      alter table(table_name) do
        modify(:inserted_at, :utc_datetime_usec)
        modify(:updated_at, :utc_datetime_usec)
      end
    end)
  end

  def down do
    alter table(:users_tokens) do
      modify(:inserted_at, :utc_datetime)
    end

    # For each of the listed tables, change the type of :inserted_at and :updated_at to microsecond precision
    @tables
    |> Enum.map(&String.to_atom/1)
    |> Enum.each(fn table_name ->
      alter table(table_name) do
        modify(:inserted_at, :utc_datetime)
        modify(:updated_at, :utc_datetime)
      end
    end)
  end
end
