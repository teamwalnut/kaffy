defmodule Api.Repo.ManualMigrations.MoveProgramToProgramEmbed do
  use Ecto.Migration
  alias Api.Repo
  import Ecto.Query
  require Logger

  def up do
    Repo.transaction(fn ->
      Repo.stream(all_binding_edits())
      |> Task.async_stream(&get_edit/1, max_concurrency: 10, timeout: 60_000)
      |> Stream.map(&update_binding_edit/1)
      |> Stream.run()
    end)
  end

  def down do
    :ok
  end

  defp get_edit(edit) do
    edit
  end

  defp update_binding_edit(edit) do
    {:ok, edit} = edit

    if edit.binding_edit_props.program_embed == nil do
      IO.puts("update binding edit for edit #{edit.id}")
      binding_edit_props = Map.from_struct(edit.binding_edit_props)
      updated_edit = Map.from_struct(edit) |> Map.put(:binding_edit_props, binding_edit_props)
      Api.Storylines.Editing.update_edits(edit.screen_id, [updated_edit])
    else
      IO.puts("no need to update #{edit.id}")
    end
  end

  defp all_binding_edits do
    from edit in Api.Storylines.Editing.Edit, where: edit.kind == :binding
  end
end
