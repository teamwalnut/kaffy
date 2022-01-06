defmodule Api.Repo.Migrations.UpdateGuideSettings do
  use Ecto.Migration
  import Ecto.Changeset
  alias Api.Repo

  def change do
    [
      "db25b88f-6cd9-41b2-8f34-ea403bb6cb68",
      "a11999c9-3c55-4102-ba69-a9f4bf206ea0",
      "79b0f1b3-a287-4972-9041-97c4c653b301",
      "6142fc64-65b6-4ec3-8de3-df89dcce4ba0"
    ]
    |> Enum.each(fn storyline_id ->
      IO.puts("storyline: #{storyline_id}")

      Api.Settings.StorylineSettings.by_storyline_id_query(storyline_id)
      |> Repo.all()
      |> Enum.each(fn setting ->
        {:ok, _} =
          Api.Settings.update_storyline_settings(setting, %{
            guides_settings: %{
              hide_dismiss: true
            }
          })
      end)
    end)

    [
      "5c88ad72-08ec-4771-bde0-f28cf6a55b66",
      "71f5d395-5048-4c53-be2d-c46daefc2378",
      "06aa3584-6a65-40d7-b3e4-bacc604eac5d",
      "963246ae-9b5e-4361-aec9-27bfd1f22dde",
      "9dae7dcf-038c-429e-ba28-0cb374e7f5d8",
      "80d753b3-778c-4dd1-9d6b-95d987dafef4"
    ]
    |> Enum.each(fn storyline_id ->
      IO.puts("storyline: #{storyline_id}")

      Api.Settings.StorylineSettings.by_storyline_id_query(storyline_id)
      |> Repo.all()
      |> Enum.each(fn setting ->
        {:ok, _} =
          Api.Settings.update_storyline_settings_unauthorized(setting, %{
            guides_settings: %{
              smooth_scrolling: false
            }
          })
      end)
    end)
  end
end
