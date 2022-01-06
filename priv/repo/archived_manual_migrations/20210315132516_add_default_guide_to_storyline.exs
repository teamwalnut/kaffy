defmodule Api.Repo.Migrations.AddDefaultGuideToStoryline do
  use Ecto.Migration

  def up do
    Api.Repo.all(storylines())
    |> Task.async_stream(&get_storyline/1, max_concurrency: 10, timeout: 60_000)
    |> Stream.map(&create_default_guide/1)
    |> Stream.run()
  end

  def down do
    :ok
  end

  defp storylines do
    Api.Storylines.Storyline
  end

  defp get_storyline(storyline) do
    storyline
  end

  defp create_default_guide(storyline) do
    {:ok, storyline} = storyline
    IO.puts("Adding default guide to storyline #{storyline.id}")
    {:ok, storyline_id_bin} = storyline.id |> Ecto.UUID.dump()

    result =
      Ecto.Adapters.SQL.query!(
        Api.Repo,
        "INSERT INTO guides (id, storyline_id, inserted_at, updated_at) VALUES($1,$2,now(),now()) RETURNING id",
        [Ecto.UUID.bingenerate(), storyline_id_bin]
      )

    guide_id = Enum.at(result.rows, 0) |> Enum.at(0)
    IO.puts("Added guide #{guide_id |> Ecto.UUID.cast!()} for storyline #{storyline.id}")
  end
end
