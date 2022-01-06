defmodule Api.Repo.Migrations.MigrateAnnotationsHasOverlayToShowDim do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # fetch all annotations with their cascaded guide_settings
    Api.Repo.all(annotations_with_guides_settings())
    |> Task.async_stream(&get_annotation/1, max_concurrency: 10, timeout: 60_000)
    |> Stream.map(&migrate_annotation_dim/1)
    |> Stream.run()
  end

  def down do
    :ok
  end

  defp get_annotation(annotation) do
    annotation
  end

  defp migrate_annotation_dim(annotation) do
    {:ok, annotation} = annotation
    # for each annoation check if it's has_overlay matches the dim_by_default value
    has_overlay = annotation.has_overlay

    # extract the dim_by_default value from the relevant settings model
    dim_by_default = cond do
      annotation.guide.demo_version_id != nil ->
        annotation.guide.demo_version.settings.guides_settings.dim_by_default

      annotation.guide.storyline_id != nil ->
        cascaded_storyline_settings =
          Api.Settings.StorylineSettings.cascade(annotation.guide.storyline.settings, annotation.guide.storyline.company.settings)

        cascaded_storyline_settings.guides_settings.dim_by_default
    end

    case has_overlay == dim_by_default do
      # if it matches - skip the annotation
      true -> IO.puts("Annotations Dim Migration: Skipping migrating has_overlay for annotation #{annotation.id}")
      # if it doesnt match - update the annotation's settings showDim to the value of has_overlay
      false ->
        IO.puts("Annotations Dim Migration: Migrating has_overlay for annotation #{annotation.id}")

        {:ok, annotation_uuid} = Ecto.UUID.dump(annotation.id)

        Api.Repo.query!(
          """
          UPDATE annotations SET settings=jsonb_set("settings"::jsonb, '{show_dim}', $1) where id = $2
          """,
          [has_overlay, annotation_uuid]
        )

    end
  end

  defp annotations_with_guides_settings do
    from annotation in Api.Annotations.Annotation, preload: [
      guide: [
        demo_version: [settings: :guides_settings],
        storyline: [
          settings: [:guides_settings], company: [settings: :guides_settings]
        ]
      ]
    ]
  end
end
