defmodule Api.Repo.Migrations.MigrateSettings do
  use Ecto.Migration
  alias Api.Repo
  import Ecto.Query

  def up do
    storyline_settings =
      from(s in "settings",
        where: not is_nil(s.storyline_id),
        select: %{
          id: s.id,
          global_js: s.global_js,
          global_css: s.global_css,
          main_color: s.main_color,
          secondary_color: s.secondary_color,
          inserted_at: s.inserted_at,
          updated_at: s.updated_at,
          guides_settings: s.guides_settings,
          disable_loader: s.disable_loader,
          storyline_id: s.storyline_id
        }
      )
      |> Repo.all()

    storyline_settings_entries = storyline_settings |> Enum.map(&Map.drop(&1, [:guides_settings]))

    Repo.insert_all("storyline_settings", storyline_settings_entries)

    storyline_guides_settings_entries =
      storyline_settings
      |> Enum.map(
        &(&1.guides_settings
          |> Map.put(:storyline_settings_id, &1.id)
          |> Map.put(:id, Ecto.UUID.bingenerate()))
      )

    Repo.insert_all("storyline_guides_settings", storyline_guides_settings_entries)

    demo_version_settings =
      from(s in "settings",
        where: not is_nil(s.demo_version_id),
        select: %{
          id: s.id,
          global_js: s.global_js,
          global_css: s.global_css,
          main_color: s.main_color,
          secondary_color: s.secondary_color,
          inserted_at: s.inserted_at,
          updated_at: s.updated_at,
          guides_settings: s.guides_settings,
          disable_loader: s.disable_loader,
          demo_version_id: s.demo_version_id
        }
      )
      |> Repo.all()

    demo_version_settings_entries =
      demo_version_settings
      |> Enum.map(&Map.drop(&1, [:guides_settings]))
      |> Enum.map(fn s ->
        %{
          id: s.id,
          global_js: s.global_js || "",
          global_css: s.global_css || "",
          main_color: s.main_color || "#6E1DF4",
          secondary_color: s.secondary_color || "#3B67E9",
          inserted_at: s.inserted_at,
          updated_at: s.updated_at,
          disable_loader: s.disable_loader || false,
          demo_version_id: s.demo_version_id
        }
      end)

    Repo.insert_all("demo_version_settings", demo_version_settings_entries)

    demo_version_guides_settings_entries =
      demo_version_settings
      |> Enum.map(&{&1.id, &1.guides_settings})
      |> Enum.map(fn {id, s} ->
        %{
          id: Ecto.UUID.bingenerate(),
          show_glow: s["show_glow"] || true,
          glow_color: s["glow_color"] || "#3b85e948",
          background_color: s["background_color"] || "#FFFFFF",
          font_color: s["font_color"] || "#292930",
          font_size: s["font_size"] || 12,
          accent_color: s["accent_color"] || "#3B67E9",
          smooth_scrolling: s["smooth_scrolling"] || true,
          hide_dismiss: s["hide_dismiss"] || false,
          dim_by_default: s["dim_by_default"] || false,
          celebrate_guides_completion: s["celebrate_guides_completion"] || true,
          demo_version_settings_id: id
        }
      end)

    Repo.insert_all("guides_settings", demo_version_guides_settings_entries)

    company_guide_settings =
      from(s in "company_settings", select: {s.id, s.guides_settings})
      |> Repo.all()

    company_guides_settings_entries =
      company_guide_settings
      |> Enum.map(fn {id, s} ->
        %{
          id: Ecto.UUID.bingenerate(),
          show_glow: s["show_glow"] || true,
          glow_color: s["glow_color"] || "#3b85e948",
          background_color: s["background_color"] || "#FFFFFF",
          font_color: s["font_color"] || "#292930",
          font_size: s["font_size"] || 12,
          accent_color: s["accent_color"] || "#3B67E9",
          smooth_scrolling: s["smooth_scrolling"] || true,
          hide_dismiss: s["hide_dismiss"] || false,
          dim_by_default: s["dim_by_default"] || false,
          celebrate_guides_completion: s["celebrate_guides_completion"] || true,
          company_settings_id: id
        }
      end)

    Repo.insert_all("guides_settings", company_guides_settings_entries)
  end

  def down do
    Ecto.Adapters.SQL.query!(
      Repo,
      "truncate table demo_version_settings, storyline_settings, guides_settings, storyline_guides_settings"
    )
  end
end
