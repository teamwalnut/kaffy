defmodule Api.Storylines.SettingsTest do
  use Api.DataCase

  alias Api.Repo
  alias Api.Settings
  alias Api.Storylines.Demos
  alias Api.Storylines.Demos.{Demo, DemoVersion}

  setup [
    :setup_user,
    :setup_company,
    :setup_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "settings" do
    test "get_storyline_settings/1 returns settings of the storyline", %{
      public_storyline: public_storyline
    } do
      assert {:ok, _} = Api.Settings.fetch_nullable_storyline_settings(public_storyline.id)
    end

    test "create_storyline_settings/1 create settings for a storyilne that doesn't have settings yet",
         %{
           public_storyline: storyline_with_settings
         } do
      storyline_with_settings = storyline_with_settings |> Repo.preload(:settings)
      storyline_with_settings.settings |> Repo.delete!()

      storyline_without_settings =
        Api.Storylines.get_storyline!(storyline_with_settings.id) |> Repo.preload(:settings)

      assert storyline_without_settings.settings == nil

      assert {:ok, %Settings.StorylineSettings{}} =
               Api.Settings.create_storyline_settings(storyline_without_settings.id)

      update_storyline =
        Api.Storylines.get_storyline!(storyline_without_settings.id) |> Repo.preload(:settings)

      assert update_storyline.settings != nil
    end

    test "create_storyline_settings/1 doesn't create settings for a storyilne that already has settings",
         %{
           public_storyline: storyline_with_settings
         } do
      assert {:error, "Settings already exist"} =
               Api.Settings.create_storyline_settings(storyline_with_settings.id)
    end

    test "update_storyline_settings/1 returns updated settings of the storyline", %{
      public_storyline: public_storyline,
      member: member
    } do
      args = %{
        main_color: "#123456",
        secondary_color: "#abcdef10",
        global_css: "global_css",
        global_js: "global_js",
        disable_loader: true,
        guides_settings: %{
          show_glow: false,
          glow_color: "#111111",
          background_color: "#222222",
          font_color: "#333333",
          font_size: 16,
          accent_color: "#444444",
          smooth_scrolling: false,
          show_dismiss_button: false,
          show_back_button: false,
          show_main_button: false,
          main_button_text: "n3xT",
          dim_by_default: true,
          celebrate_guides_completion: false,
          show_avatar: true,
          avatar_url: "https://www.walnut.io",
          avatar_title: "Paz from Walnut",
          fab: %{
            enabled: true,
            position: :top_right,
            text: "Only Demoz",
            target_url: "https://www.demo.com"
          }
        }
      }

      assert {:ok, %Settings.StorylineSettings{} = updated_settings} =
               Api.Settings.update_storyline_settings(public_storyline.id, args, member)

      assert updated_settings.storyline_id == public_storyline.id
      assert updated_settings.main_color == "#123456"
      assert updated_settings.secondary_color == "#abcdef10"
      assert updated_settings.global_css == "global_css"
      assert updated_settings.global_js == "global_js"
      assert updated_settings.disable_loader == true
      assert updated_settings.guides_settings.show_glow == false
      assert updated_settings.guides_settings.glow_color == "#111111"
      assert updated_settings.guides_settings.background_color == "#222222"
      assert updated_settings.guides_settings.font_color == "#333333"
      assert updated_settings.guides_settings.accent_color == "#444444"
      assert updated_settings.guides_settings.font_size == 16
      assert updated_settings.guides_settings.smooth_scrolling == false
      assert updated_settings.guides_settings.show_dismiss_button == false
      assert updated_settings.guides_settings.show_back_button == false
      assert updated_settings.guides_settings.show_main_button == false
      assert updated_settings.guides_settings.main_button_text == "n3xT"
      assert updated_settings.guides_settings.dim_by_default == true
      assert updated_settings.guides_settings.show_avatar == true
      assert updated_settings.guides_settings.avatar_url == "https://www.walnut.io"
      assert updated_settings.guides_settings.avatar_title == "Paz from Walnut"
      assert updated_settings.guides_settings.fab.enabled == true
      assert updated_settings.guides_settings.fab.position == :top_right
      assert updated_settings.guides_settings.fab.text == "Only Demoz"
      assert updated_settings.guides_settings.fab.target_url == "https://www.demo.com"
    end

    test "copy_storyline_settings/2 copies settings from origin_storyline_id to the target storyline",
         %{
           public_storyline: origin_storyline,
           member: member
         } do
      {:ok, original_settings} =
        Api.Settings.update_storyline_settings(
          origin_storyline.id,
          %{
            main_color: "#123456",
            secondary_color: "#abcdef",
            guides_settings: %{
              show_glow: false,
              glow_color: "#111111",
              fab: %{
                enabled: true,
                position: :top_right,
                text: "Only Demoz",
                target_url: "https://www.demo.com"
              }
            }
          },
          member
        )

      target_storyline =
        empty_storyline_fixture(member, %{is_public: true}) |> Repo.preload(:settings)

      assert target_storyline.settings == nil

      assert {:ok, %Settings.StorylineSettings{}} =
               Api.Settings.copy_storyline_settings(origin_storyline.id, target_storyline)

      target_storyline =
        Api.Storylines.get_storyline!(target_storyline.id)
        |> Repo.preload(settings: [:guides_settings])

      copied_storyline_settings = target_storyline.settings
      assert copied_storyline_settings.main_color == original_settings.main_color
      assert copied_storyline_settings.secondary_color == original_settings.secondary_color
      assert copied_storyline_settings.guides_settings.show_glow == false
      assert copied_storyline_settings.guides_settings.glow_color == "#111111"
      assert copied_storyline_settings.guides_settings.fab.enabled == true
      assert copied_storyline_settings.guides_settings.fab.position == :top_right
      assert copied_storyline_settings.guides_settings.fab.text == "Only Demoz"
      assert copied_storyline_settings.guides_settings.fab.target_url == "https://www.demo.com"
    end

    test "copy_storyline_settings/2 copies settings from origin_storyline_id to the target demo's latest demo_version",
         %{
           public_storyline: origin_storyline,
           member: member
         } do
      {:ok, original_settings} =
        Api.Settings.update_storyline_settings(
          origin_storyline.id,
          %{
            main_color: "#123456",
            secondary_color: "#abcdef",
            guides_settings: %{
              show_glow: false,
              glow_color: "#111111",
              fab: %{
                enabled: true,
                position: :top_right,
                text: "Only Demoz",
                target_url: "https://www.demo.com"
              }
            }
          },
          member
        )

      {:ok, temp_demo_version} =
        %DemoVersion{created_by_id: member.id, start_screen_id: origin_storyline.start_screen_id}
        |> DemoVersion.changeset(%{})
        |> Api.Repo.insert()

      {:ok, demo} =
        %Demo{storyline_id: origin_storyline.id, active_version_id: temp_demo_version.id}
        |> Demo.changeset(%{name: "Demo"})
        |> Api.Repo.insert()

      DemoVersion.update_demo_id_changeset(temp_demo_version, %{demo_id: demo.id})
      |> Api.Repo.update()

      target_demo = demo |> Repo.preload(active_version: [:settings])

      assert target_demo.active_version.settings == nil

      assert {:ok, %Settings.DemoVersionSettings{}} =
               Api.Settings.copy_storyline_settings(origin_storyline.id, target_demo)

      target_demo =
        Demos.get_demo!(target_demo.id)
        |> Repo.preload(active_version: [settings: [:guides_settings]])

      copied_storyline_settings = target_demo.active_version.settings
      assert copied_storyline_settings.main_color == original_settings.main_color
      assert copied_storyline_settings.secondary_color == original_settings.secondary_color
      assert copied_storyline_settings.guides_settings.show_glow == false
      assert copied_storyline_settings.guides_settings.glow_color == "#111111"
      assert copied_storyline_settings.guides_settings.fab.enabled == true
      assert copied_storyline_settings.guides_settings.fab.position == :top_right
      assert copied_storyline_settings.guides_settings.fab.text == "Only Demoz"
      assert copied_storyline_settings.guides_settings.fab.target_url == "https://www.demo.com"
    end
  end

  describe "settings/guides/fab" do
    test "update_storyline_settings/1 errors when setting incorrect values for FAB", %{
      public_storyline: public_storyline,
      member: member
    } do
      args = %{
        guides_settings: %{
          fab: %{
            enabled: true
          }
        }
      }

      assert {:error, changeset} =
               Api.Settings.update_storyline_settings(public_storyline.id, args, member)

      errors = errors_on(changeset).guides_settings.fab
      assert "can't be blank" in errors.target_url
      assert "can't be blank" in errors.text
    end

    test "update_storyline_settings/1 keep fab values when updating", %{
      public_storyline: public_storyline,
      member: member
    } do
      args = %{
        guides_settings: %{
          fab: %{
            enabled: true,
            position: :top_right,
            text: "Only Demoz",
            target_url: "https://www.demo.com"
          }
        }
      }

      assert {:ok, %Settings.StorylineSettings{}} =
               Api.Settings.update_storyline_settings(public_storyline.id, args, member)

      args = %{
        guides_settings: %{
          fab: %{
            enabled: false
          }
        }
      }

      assert {:ok, %Settings.StorylineSettings{} = updated_settings} =
               Api.Settings.update_storyline_settings(public_storyline.id, args, member)

      assert updated_settings.guides_settings.fab.enabled == false
      assert updated_settings.guides_settings.fab.position == :top_right
      assert updated_settings.guides_settings.fab.text == "Only Demoz"
      assert updated_settings.guides_settings.fab.target_url == "https://www.demo.com"
    end
  end
end
