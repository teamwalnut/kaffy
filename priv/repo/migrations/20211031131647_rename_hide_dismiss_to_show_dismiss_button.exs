defmodule Api.Repo.Migrations.RenameHideDismissToShowDismissButton do
  use Ecto.Migration

  def up do
    rename(table(:guides_settings), :hide_dismiss, to: :show_dismiss_button)

    alter table(:guides_settings) do
      modify(:show_dismiss_button, :boolean, default: true, null: false)
    end

    rename(table(:storyline_guides_settings), :hide_dismiss, to: :show_dismiss_button)
  end

  def down do
    rename(table(:guides_settings), :show_dismiss_button, to: :hide_dismiss)

    alter table(:guides_settings) do
      modify(:hide_dismiss, :boolean, default: false, null: false)
    end

    rename(table(:storyline_guides_settings), :show_dismiss_button, to: :hide_dismiss)
  end
end
