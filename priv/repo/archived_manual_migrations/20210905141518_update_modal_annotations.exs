defmodule Api.Repo.Migrations.UpdateModalAnnotations do
  use Ecto.Migration

  def up do
    Ecto.Adapters.SQL.query!(
      Api.Repo,
      """
      UPDATE annotations set has_overlay=true where kind = 'modal'
      """
    )
  end

  def down do
    :ok
  end
end
