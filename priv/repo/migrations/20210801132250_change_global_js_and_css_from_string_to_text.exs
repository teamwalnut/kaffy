defmodule Api.Repo.Migrations.ChangeGlobalJsAndCssFromStringToText do
  use Ecto.Migration

  def up do
    alter table(:settings) do
      modify(:global_js, :text)
      modify(:global_css, :text)
    end
  end

  def down do
    alter table(:settings) do
      modify(:global_js, :string)
      modify(:global_css, :string)
    end
  end
end
