defmodule Api.Repo.Migrations.AddFrameSelectors do
  use Ecto.Migration

  def change do
    alter table(:edits) do
      add(:frame_selectors, {:array, :text})
    end
  end
end
