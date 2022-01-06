defmodule Api.Repo.Migrations.CompactStorylineFlowsAndScreens do
  use Ecto.Migration
  import Ecto.Query
  alias Ecto.{Adapters, Multi}

  def up do
    Api.Repo.all(storylines_with_flows_and_screens_in_order())
    |> Task.async_stream(&get_storyline/1, max_concurrency: 10, timeout: 60_000)
    |> Stream.map(&compact_storyline/1)
    |> Stream.run()
  end

  def down do
    :ok
  end

  defp get_storyline(storyline) do
    storyline
  end

  defp compact_storyline(storyline) do
    {:ok, storyline} = storyline

    compact_flows(storyline)

    storyline.flows
    |> Enum.each(fn flow -> Api.Storylines.ScreenGrouping.compact_flow(flow.id) end)
  end

  defp compact_flows(storyline) do
    multi =
      Multi.run(Multi.new(), "deferred", fn _repo, _ ->
        Adapters.SQL.query!(Api.Repo, "SET CONSTRAINTS flows_position_storyline_id DEFERRED")
        {:ok, nil}
      end)

    changesets =
      storyline.flows
      |> Enum.with_index(1)
      |> Enum.reject(fn {flow, index} ->
        flow.position == index
      end)
      |> Enum.map(fn {flow, index} ->
        Api.Storylines.ScreenGrouping.Flow.reposition_changeset(flow, %{position: index})
      end)

    multi =
      changesets
      |> Enum.reduce(multi, fn changeset, multi_acc ->
        Multi.update(multi_acc, Integer.to_string(changeset.changes.position), changeset)
      end)

    multi_result = Api.Repo.transaction(multi)

    case multi_result do
      {:ok, _} -> {:ok, "entity compacted successfully"}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  defp storylines_with_flows_and_screens_in_order do
    flow_screen_query = Api.Storylines.ScreenGrouping.FlowScreen.order_by_position_query()

    flows_query =
      from flow in Api.Storylines.ScreenGrouping.Flow,
        order_by: [asc: :position],
        preload: [flow_screens: ^flow_screen_query]

    from storyline in Api.Storylines.Storyline, preload: [flows: ^flows_query]
  end
end
