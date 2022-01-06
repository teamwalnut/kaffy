defmodule ApiWeb.GraphQL.UpdateCompanySettings do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :update_settings,
    ApiWeb.Schema,
    "test/support/mutations/settings/UpdateCompanySettings.gql"
  )

  setup [
    :register_and_log_in_member
  ]

  test "update company settings without existing settings", %{context: context} do
    query_gql_by(
      :update_settings,
      variables: %{
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
          "showDismissButton" => true,
          "showBackButton" => false,
          "showMainButton" => false,
          "mainButtonText" => "n3xT",
          "dimByDefault" => true,
          "dimStyle" => "DARK",
          "celebrateGuidesCompletion" => false,
          "showAvatar" => true,
          "avatarUrl" => "https://dummyimage.com/256x256/000/fff",
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
    |> match_snapshot(scrub: ["id"])
  end

  test "authorization", %{context: context} do
    TestAccess.assert_roles(
      &query_gql_by(
        :update_settings,
        variables: %{
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
            "showDismissButton" => true,
            "showBackButton" => false,
            "showMainButton" => false,
            "mainButtonText" => "n3xT",
            "dimByDefault" => true,
            "dimStyle" => "DARK",
            "celebrateGuidesCompletion" => false,
            "showAvatar" => true,
            "avatarUrl" => "https://dummyimage.com/256x256/000/fff",
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
      %TestAccess{viewer: false, presenter: false, editor: false, company_admin: true}
    )
  end

  test "update company settings with null main color", %{context: context} do
    query_gql_by(
      :update_settings,
      variables: %{
        "mainColor" => nil,
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
          "celebrateGuidesCompletion" => false,
          "showAvatar" => true,
          "avatarUrl" => "https://dummyimage.com/256x256/000/fff",
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
    |> match_snapshot(scrub: ["id"])
  end

  test "update company settings with main color not in payload", %{context: context} do
    query_gql_by(
      :update_settings,
      variables: %{
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
          "showDismissButton" => true,
          "showBackButton" => false,
          "showMainButton" => false,
          "mainButtonText" => "n3xT",
          "dimByDefault" => true,
          "celebrateGuidesCompletion" => false,
          "showAvatar" => true,
          "avatarUrl" => "https://dummyimage.com/256x256/000/fff",
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
    |> match_snapshot(scrub: ["id"])
  end

  test "update company settings with nullable guide settings", %{context: context} do
    query_gql_by(
      :update_settings,
      variables: %{
        "mainColor" => "#123456",
        "secondaryColor" => "#abcdef10",
        "disableLoader" => true,
        "guidesSettings" => %{
          "glowColor" => nil,
          "showGlow" => false,
          "fontSize" => 14,
          "fontColor" => "#123456",
          "backgroundColor" => "#654321",
          "accentColor" => "#444444",
          "smoothScrolling" => false,
          "showDismissButton" => true,
          "showBackButton" => false,
          "showMainButton" => false,
          "mainButtonText" => "n3xT",
          "dimByDefault" => true,
          "celebrateGuidesCompletion" => false,
          "showAvatar" => true,
          "avatarUrl" => "https://dummyimage.com/256x256/000/fff",
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
    |> match_snapshot(scrub: ["id"])
  end

  test "update company settings when there are already settings", %{
    company: company,
    context: context
  } do
    company_settings_fixture(company)

    query_gql_by(
      :update_settings,
      variables: %{
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
          "showDismissButton" => true,
          "showBackButton" => false,
          "showMainButton" => false,
          "mainButtonText" => "n3xT",
          "dimByDefault" => true,
          "dimStyle" => "SOFT",
          "celebrateGuidesCompletion" => false,
          "showAvatar" => true,
          "avatarUrl" => "https://dummyimage.com/256x256/000/fff",
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
    |> match_snapshot(scrub: ["id"])
  end
end
