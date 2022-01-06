defmodule ApiWeb.GraphQL.UpdateStorylineSettings do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :update_settings,
    ApiWeb.Schema,
    "test/support/mutations/settings/UpdateStorylineSettings.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline
  ]

  describe "UpdateStorylineSettings" do
    test "it updates the storyline settings when called with valid data", %{
      context: context,
      public_storyline: %{id: storyline_id} = _storyline
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :update_settings,
                 variables: %{
                   "storylineId" => storyline_id,
                   "mainColor" => "#123456",
                   "secondaryColor" => "#abcdef10",
                   "disableLoader" => true,
                   "guidesSettings" => %{
                     "glowColor" => "#efcbb150",
                     "showGlow" => false,
                     "fontSize" => 14,
                     "fontColor" => "#123456",
                     "backgroundColor" => "#654321",
                     "accentColor" => "#444444",
                     "smoothScrolling" => false,
                     "showDismissButton" => false,
                     "showBackButton" => false,
                     "showMainButton" => false,
                     "mainButtonText" => "n3xT",
                     "dimByDefault" => true,
                     "dimStyle" => "DARK",
                     "celebrateGuidesCompletion" => false,
                     "showAvatar" => true,
                     "avatarUrl" => "https://www.walnut.io",
                     "avatarTitle" => "Paz from Walnut",
                     "fab" => %{
                       "enabled" => true,
                       "position" => "BOTTOM_LEFT",
                       "text" => "Call to Action",
                       "targetUrl" => "https://walnut.io"
                     }
                   },
                   "globalCss" => "css",
                   "globalJs" => "js"
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "updateStorylineSettings"])
      assert result["id"] != nil

      {:ok, settings} = Api.Settings.fetch_nullable_storyline_settings(storyline_id)
      settings = settings |> Repo.preload(:guides_settings)

      assert settings.main_color == "#123456"
      assert settings.secondary_color == "#abcdef10"
      assert settings.global_css == "css"
      assert settings.global_js == "js"
      assert settings.disable_loader == true
      assert settings.guides_settings.glow_color == "#efcbb150"
      assert settings.guides_settings.show_glow == false
      assert settings.guides_settings.font_size == 14
      assert settings.guides_settings.font_color == "#123456"
      assert settings.guides_settings.background_color == "#654321"
      assert settings.guides_settings.accent_color == "#444444"
      assert settings.guides_settings.smooth_scrolling == false
      assert settings.guides_settings.show_dismiss_button == false
      assert settings.guides_settings.show_back_button == false
      assert settings.guides_settings.show_main_button == false
      assert settings.guides_settings.main_button_text == "n3xT"
      assert settings.guides_settings.dim_by_default == true
      assert settings.guides_settings.dim_style == :dark
      assert settings.guides_settings.celebrate_guides_completion == false
      assert settings.guides_settings.show_avatar == true
      assert settings.guides_settings.avatar_url == "https://www.walnut.io"
      assert settings.guides_settings.avatar_title == "Paz from Walnut"
    end

    test "authorize", %{context: context, public_storyline: %{id: storyline_id} = _storyline} do
      TestAccess.assert_roles(
        &query_gql_by(
          :update_settings,
          variables: %{
            "storylineId" => storyline_id,
            "mainColor" => "#123456",
            "secondaryColor" => "#abcdef10",
            "disableLoader" => true,
            "guidesSettings" => %{
              "glowColor" => "#efcbb150",
              "showGlow" => false,
              "fontSize" => 14,
              "fontColor" => "#123456",
              "backgroundColor" => "#654321",
              "accentColor" => "#444444",
              "smoothScrolling" => false,
              "showDismissButton" => false,
              "showBackButton" => false,
              "showMainButton" => false,
              "mainButtonText" => "n3xT",
              "dimByDefault" => true,
              "dimStyle" => "DARK",
              "celebrateGuidesCompletion" => false,
              "showAvatar" => true,
              "avatarUrl" => "https://www.walnut.io",
              "avatarTitle" => "Paz from Walnut",
              "fab" => %{
                "enabled" => true,
                "position" => "BOTTOM_LEFT",
                "text" => "Call to Action",
                "targetUrl" => "https://walnut.io"
              }
            },
            "globalCss" => "css",
            "globalJs" => "js"
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "it doesn't update the storyline settings if called with invalid data", %{
      context: context,
      public_storyline: %{id: storyline_id} = _storyline
    } do
      settings_before_update = Api.Settings.get_storyline_settings(storyline_id)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_settings,
                 variables: %{
                   "storylineId" => storyline_id,
                   "mainColor" => "#qqwe12"
                 },
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Main_color has invalid format"

      settings_after_update_failure = Api.Settings.get_storyline_settings(storyline_id)
      assert settings_after_update_failure.main_color == settings_before_update.main_color
    end

    test "in can be updated with nullable data, it will then default to the company settings",
         %{
           context: context,
           public_storyline: %{id: storyline_id} = _storyline,
           company: company,
           member: member
         } do
      company_settings_fixture(company)

      Api.Settings.update_storyline_settings(
        storyline_id,
        %{
          main_color: "#FF0000",
          guides_settings: %{accent_color: "#AAAAAA"}
        },
        member
      )

      query_gql_by(
        :update_settings,
        variables: %{
          "storylineId" => storyline_id,
          "mainColor" => nil,
          "secondaryColor" => nil,
          "disableLoader" => nil,
          "guidesSettings" => %{
            "glowColor" => nil,
            "showGlow" => nil,
            "fontSize" => nil,
            "fontColor" => nil,
            "backgroundColor" => nil,
            "accentColor" => nil,
            "smoothScrolling" => nil,
            "showDismissButton" => nil,
            "showBackButton" => nil,
            "showMainButton" => nil,
            "mainButtonText" => nil,
            "dimByDefault" => nil,
            "dimStyle" => nil,
            "celebrateGuidesCompletion" => nil,
            "showAvatar" => nil,
            "avatarUrl" => nil,
            "avatarTitle" => nil,
            "fab" => %{
              "enabled" => nil,
              "position" => nil,
              "text" => nil,
              "targetUrl" => nil
            }
          },
          "globalCss" => "css",
          "globalJs" => "js"
        },
        context: context
      )
      |> match_snapshot(scrub: "id")
    end

    test "in can be updated with nullable data, without company settings it wil default to the global settings",
         %{
           context: context,
           public_storyline: %{id: storyline_id} = _storyline,
           member: member
         } do
      Api.Settings.update_storyline_settings(
        storyline_id,
        %{
          main_color: "#FF0000",
          guides_settings: %{accent_color: "#AAAAAA"}
        },
        member
      )

      query_gql_by(
        :update_settings,
        variables: %{
          "storylineId" => storyline_id,
          "mainColor" => nil,
          "secondaryColor" => nil,
          "disableLoader" => nil,
          "guidesSettings" => %{
            "glowColor" => nil,
            "showGlow" => nil,
            "fontSize" => nil,
            "fontColor" => nil,
            "backgroundColor" => nil,
            "accentColor" => nil,
            "smoothScrolling" => nil,
            "showDismissButton" => nil,
            "showBackButton" => nil,
            "showMainButton" => nil,
            "mainButtonText" => nil,
            "dimByDefault" => nil,
            "dimStyle" => nil,
            "celebrateGuidesCompletion" => nil,
            "showAvatar" => nil,
            "avatarUrl" => nil,
            "avatarTitle" => nil,
            "fab" => %{
              "enabled" => nil,
              "position" => nil,
              "text" => nil,
              "targetUrl" => nil
            }
          },
          "globalCss" => "css",
          "globalJs" => "js"
        },
        context: context
      )
      |> match_snapshot(scrub: ["id"])
    end
  end
end
