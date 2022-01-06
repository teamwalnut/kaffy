defmodule Api.Repo.Migrations.ReverseValuesForRenamedDismissButtonField do
  use Ecto.Migration

  def up do
    Ecto.Adapters.SQL.query!(
      Api.Repo,
      """
      UPDATE guides_settings SET show_dismiss_button = NOT show_dismiss_button
      """
    )

    Ecto.Adapters.SQL.query!(
      Api.Repo,
      """
      UPDATE storyline_guides_settings SET show_dismiss_button = NOT show_dismiss_button where show_dismiss_button is not null
      """
    )
  end

  def down do
    :ok
  end
end
