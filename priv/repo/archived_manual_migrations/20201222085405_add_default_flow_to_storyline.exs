defmodule Api.Repo.ManualMigrations.AddDefaultFlowToStoryline do
  use Ecto.Migration
  import Ecto.Query
  require Logger

  def up do
    Api.Repo.all(storylines_with_screens())
    |> Task.async_stream(&get_storyline/1, max_concurrency: 10, timeout: 60_000)
    |> Stream.map(&create_default_flow/1)
    |> Stream.run()
  end

  def down do
    :ok
  end

  defp get_storyline(storyline) do
    storyline
  end

  defp create_default_flow(storyline) do
    {:ok, storyline} = storyline
    IO.puts("Adding default flow to storyline #{storyline.id}")
    {:ok, storyline_id_bin} = storyline.id |> Ecto.UUID.dump()

    result =
      Ecto.Adapters.SQL.query!(
        Api.Repo,
        "INSERT INTO flows (id, storyline_id, position, inserted_at, updated_at, is_default, name) VALUES($1,$2,$3,now(),now(),true,'Default') RETURNING id",
        [Ecto.UUID.bingenerate(), storyline_id_bin, 1]
      )

    flow_id = Enum.at(result.rows, 0) |> Enum.at(0)

    storyline.screens
    |> Enum.with_index()
    |> Enum.each(fn {screen, index} ->
      IO.puts(
        "Adding screen #{screen.id} to flow #{flow_id |> Ecto.UUID.cast!()} for storyline #{storyline.id}"
      )

      {:ok, screen_id_bin} = screen.id |> Ecto.UUID.dump()

      Ecto.Adapters.SQL.query!(
        Api.Repo,
        "INSERT INTO flow_screens (id, flow_id, screen_id, position, inserted_at, updated_at) VALUES($1, $2, $3, $4, now(), now()) RETURNING id",
        [Ecto.UUID.bingenerate(), flow_id, screen_id_bin, index + 1]
      )

      IO.puts(
        "Added screen #{screen.id} to flow #{flow_id |> Ecto.UUID.cast!()} for storyline #{storyline.id}"
      )
    end)

    IO.puts("Added default flow to storyline #{storyline.id} successfully")
  end

  defp storylines_with_screens do
    screen_query = from screen in Api.Storylines.Screen, order_by: [asc: screen.name]
    from storyline in Api.Storylines.Storyline, preload: [screens: ^screen_query]
  end
end
