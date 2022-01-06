defmodule Api.Repo.Migrations.SetDefaultAccentColor do
  use Ecto.Migration

  def change do
    Api.Repo.all(Api.Settings.StorylineSettings)
    |> Enum.each(fn setting ->
      {:ok, _} =
        Api.Settings.update_storyline_settings_unauthorized(setting, %{
          guides_settings: %{
            accent_color: setting.guides_settings.font_color
          }
        })
    end)
  end
end
