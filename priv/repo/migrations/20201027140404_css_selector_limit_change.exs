defmodule Api.Repo.Migrations.CssSelectorLimitChange do
  use Ecto.Migration

  def change do
    alter table(:edits) do
      modify(:css_selector, :text)
    end
  end
end
