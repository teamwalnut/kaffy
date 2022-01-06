defmodule Api.Repo.Migrations.AddRichTextAnnotations do
  use Ecto.Migration

  def up do
    alter table(:annotations) do
      add(:rich_text, :map)
      modify(:message, :text, null: true, default: "")
    end
  end

  def down do
    alter table(:annotations) do
      remove(:rich_text)
      modify(:message, :text, null: false, default: "")
    end
  end
end
