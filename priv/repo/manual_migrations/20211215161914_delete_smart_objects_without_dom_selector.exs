defmodule Api.Repo.Migrations.DeleteSmartObjectsWithoutDomSelector do
  use Ecto.Migration

  def up do
    # per each screen set smart_object_instances column to be null
    # if instances array contains an instance object that has no dom_selector key
    Ecto.Adapters.SQL.query!(
      Api.Repo,
      """
      UPDATE screens SET smart_object_instances = null where id IN (
          SELECT id
          FROM screens AS sc, jsonb_array_elements(
              (
                SELECT sc.smart_object_instances
                FROM screens
                WHERE id = sc.id
              )
          ) AS instances
          WHERE instances#>'{dom_selector}' IS NULL
      )
      """
    )

    Ecto.Adapters.SQL.query!(
      Api.Repo,
      """
      DELETE FROM smart_object_classes where smart_object_classes.dom_selector is null
      """
    )
  end

  def down do
    :ok
  end
end
