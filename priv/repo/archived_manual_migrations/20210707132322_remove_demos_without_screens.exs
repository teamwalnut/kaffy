defmodule Api.Repo.Migrations.RemoveDemosWithoutScreens do
  use Ecto.Migration

  def up do
    Ecto.Adapters.SQL.query!(
      Api.Repo,
      "delete from demos where id in (
          select demo_id from demo_versions where start_screen_id is null
      )",
      []
    )
  end

  def down do
    :ok
  end
end
