defmodule Api.Repo.Migrations.CreateSettingsForDemoVersions do
  use Ecto.Migration

  def up do
    Api.Repo.all(demo_versions())
    |> Task.async_stream(&get_demo_version/1, max_concurrency: 10, timeout: 60_000)
    |> Stream.map(&create_demo_version_settings/1)
    |> Stream.run()
  end

  def down do
    :ok
  end

  defp demo_versions do
    Api.Storylines.Demos.DemoVersion
  end

  defp get_demo_version(storyline) do
    storyline
  end

  defp create_demo_version_settings(demo_version) do
    {:ok, demo_version} = demo_version

    demo_version = demo_version |> Api.Repo.preload(:settings)

    if demo_version.settings != nil do
      IO.puts(
        "Skipping creating settings for demo_version #{demo_version.id} as it already has settings"
      )
    else
      IO.puts("Creating settings for demo_version #{demo_version.id}")

      {:ok, demo_version_id_bin} = demo_version.id |> Ecto.UUID.dump()

      result =
        Ecto.Adapters.SQL.query!(
          Api.Repo,
          "INSERT INTO settings (id, demo_version_id, main_color, secondary_color, inserted_at, updated_at) VALUES($1,$2,$3,$4,now(),now()) RETURNING id",
          [Ecto.UUID.bingenerate(), demo_version_id_bin, "#6E1DF4", "#3B67E9"]
        )

      settings_id = Enum.at(result.rows, 0) |> Enum.at(0) |> Ecto.UUID.cast!()
      IO.puts("Created settings #{settings_id} for demo_version #{demo_version.id}")
    end
  end
end
