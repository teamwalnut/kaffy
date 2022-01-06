defmodule Api.Repo.Migrations.AnnotationsCssSelectorLimitChange do
  use Ecto.Migration

  def change do
    alter table(:annotations) do
      modify(:css_selector, :text)
    end
  end
end
