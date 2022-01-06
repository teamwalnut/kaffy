defmodule Api.Repo.Migrations.IncreaseAnnotationMessageLimit do
  use Ecto.Migration

  def change do
    alter table(:annotations) do
      modify(:message, :text)
      modify(:frame_selectors, {:array, :text})
    end
  end
end
