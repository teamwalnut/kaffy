defmodule Api.Repo.Migrations.CreateSettingsForStorylines do
  use Ecto.Migration

  def up do
    Api.Repo.all(storylines())
    |> Task.async_stream(&get_storyline/1, max_concurrency: 10, timeout: 60_000)
    |> Stream.map(&create_storyline_settings/1)
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

  defp create_storyline_settings(storyline) do
    {:ok, storyline} = storyline
    IO.puts("Creating settings to storyline #{storyline.id}")

    {:ok, storyline_id_bin} = storyline.id |> Ecto.UUID.dump()

    result =
      Ecto.Adapters.SQL.query!(
        Api.Repo,
        "INSERT INTO settings (id, storyline_id, main_color, secondary_color, inserted_at, updated_at) VALUES($1,$2,$3,$4,now(),now()) RETURNING id",
        [Ecto.UUID.bingenerate(), storyline_id_bin, "#6E1DF4", "#3B67E9"]
      )

    settings_id = Enum.at(result.rows, 0) |> Enum.at(0) |> Ecto.UUID.cast!()
    IO.puts("Created settings #{settings_id} for storyline #{storyline.id}")
  end
end
