defmodule Api.Repo.Migrations.AddDefaultDemoToStoryline do
  use Ecto.Migration

  def up do
    Api.Repo.all(storylines())
    |> Task.async_stream(&get_storyline/1, max_concurrency: 10, timeout: 60_000)
    |> Stream.map(&create_default_demo/1)
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

  defp create_default_demo(storyline) do
    {:ok, storyline} = storyline
    storyline = storyline |> Api.Repo.preload(:owner)
    IO.puts("Adding default demo to storyline #{storyline.id}")

    # TODO(itay): Currently using the storyline name as the demo name, verify this is the desired behavior.
    {:ok, %{demo: created_demo}} =
      Api.Storylines.Demos.create_demo(
        storyline.id,
        %{id: storyline.id, name: storyline.name},
        storyline.owner
      )

    IO.puts(
      "Created demo using Api.Storylines.Demos.create_demo/3 successfully. id: #{created_demo.id}"
    )
  end
end
