defmodule ApiWeb.AnalyticsTest do
  use ApiWeb.ConnCase, async: true
  alias Api.Companies.Company
  alias Api.Repo
  alias ApiWeb.Analytics
  import Hammox

  setup [:setup_user, :setup_company, :setup_member, :verify_on_exit!]

  describe "when a walnut user" do
    for email <- ["god@walnut.io", "godess@teamwalnut.com"] do
      test "should not call provider with email: #{email}", %{member: member} do
        user = %Api.Accounts.User{email: unquote(email), members: [member]}

        uuid = Ecto.UUID.generate()

        Analytics.identify(user)

        Analytics.report_storyline_created(user, %Api.Storylines.Storyline{})
        Analytics.report_storyline_updated(user, %Api.Storylines.Storyline{})

        Analytics.report_flow_created(user, %Api.Storylines.ScreenGrouping.Flow{})
        Analytics.report_flow_deleted(user, %Api.Storylines.ScreenGrouping.Flow{})
        Analytics.report_flow_renamed(user, %Api.Storylines.ScreenGrouping.Flow{})

        Analytics.report_screen_added(user, %Api.Storylines.Screen{})
        Analytics.report_screen_deleted(user, %Api.Storylines.Screen{})
        Analytics.report_screen_renamed(user, %Api.Storylines.Screen{})

        Analytics.report_edit_created(user, %Api.Storylines.Editing.Edit{})
        Analytics.report_edit_updated(user, %Api.Storylines.Editing.Edit{})
        Analytics.report_edit_deleted(user, %Api.Storylines.Editing.Edit{})

        Analytics.report_guide_created(user, uuid, %Api.Annotations.Guide{})
        Analytics.report_guide_deleted(user, %Api.Annotations.Guide{})
        Analytics.report_guide_renamed(user, %Api.Annotations.Guide{})
        Analytics.report_annotation_added(user, uuid, %Api.Annotations.Annotation{})
        Analytics.report_annotation_updated(user, uuid, %Api.Annotations.Annotation{})
        Analytics.report_annotation_deleted(user, uuid, %Api.Annotations.Annotation{})
      end
    end
  end

  test "report is_paying correctly", %{
    company: company,
    user: user
  } do
    %{email: user_email, first_name: first_name, last_name: last_name} = user
    %{name: company_name} = company

    ApiWeb.Analytics.ProviderMock
    |> expect(:identify, fn ^user_email,
                            %{
                              company: %{name: ^company_name},
                              company_name: ^company_name,
                              is_paying: false,
                              first_name: ^first_name,
                              last_name: ^last_name,
                              role: "Admin"
                            } ->
      :ok
    end)

    Analytics.identify(user)

    company
    |> Company.update_changeset(%{is_paying: true})
    |> Repo.update!()

    ApiWeb.Analytics.ProviderMock
    |> expect(:identify, fn ^user_email,
                            %{
                              company: %{name: ^company_name},
                              company_name: ^company_name,
                              is_paying: true,
                              first_name: ^first_name,
                              last_name: ^last_name
                            } ->
      :ok
    end)

    Analytics.identify(user)
  end
end
