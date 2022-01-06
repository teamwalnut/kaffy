defmodule Api.Repo.Migrations.LinkEditsToNewStructure do
  use Ecto.Migration

  def up do
    Ecto.Adapters.SQL.query!(
      Api.Repo,
      """
          UPDATE edits SET link_edit_props = cast(concat(
              '{"target_screen_id": ',link_edit_props -> 'target_screen_id', ',',
              '"destination": {"kind":"screen", "id": ',link_edit_props -> 'target_screen_id', '}}') as json)
          WHERE kind = 'link'
            and (link_edit_props -> 'target_screen_id')::text != 'null'
            and link_edit_props -> 'target_screen_id' is not null
      """
    )

    Ecto.Adapters.SQL.query!(
      Api.Repo,
      """
          UPDATE edits SET link_edit_props = cast(concat(
              '{"target_screen_id": ',link_edit_props -> 'destination' -> 'id', ',',
              '"destination": {"kind":"screen", "id": ',link_edit_props -> 'destination' -> 'id', '}}') as json)
          WHERE kind = 'link'
            and (link_edit_props -> 'target_screen_id' is null or (link_edit_props -> 'target_screen_id')::text = 'null')
            and link_edit_props -> 'destination' -> 'id' is not null;
      """
    )
  end

  def down do
    :ok
  end
end
