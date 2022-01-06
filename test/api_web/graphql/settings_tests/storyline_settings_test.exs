defmodule ApiWeb.GraphQL.StorylineSettingsTest do
  use ApiWeb.GraphQLCase

  load_gql(:storyline, ApiWeb.Schema, "test/support/queries/StorylineWithSettings.gql")

  def context(member) do
    %{current_user: member.user, current_member: member}
  end

  def setup_data do
    user = user_fixture()
    company = Api.CompaniesFixtures.company_fixture()
    {:ok, member} = Api.Companies.add_member(user.id, company)

    private_storyline = Api.StorylineCreationFixtures.private_storyline_creation_fixture(member)
    public_storyline = Api.StorylineCreationFixtures.public_storyline_creation_fixture(member)

    %{
      user: user,
      member: member,
      company: company,
      private_storyline: private_storyline,
      public_storyline: public_storyline
    }
  end

  setup do
    setup_data()
  end

  test "query settings when there are no settings", %{
    private_storyline: storyline,
    member: member
  } do
    query_gql_by(:storyline,
      variables: %{"id" => storyline.id},
      context: context(member)
    )
    |> match_snapshot(scrub: ["id"])
  end

  test "query settings when there are only company settings", %{
    private_storyline: storyline,
    member: member,
    company: company
  } do
    company_settings_fixture(company)

    query_gql_by(:storyline,
      variables: %{"id" => storyline.id},
      context: context(member)
    )
    |> match_snapshot(scrub: ["id"])
  end

  test "query storylines settings with a different main color", %{
    private_storyline: storyline,
    company: company,
    member: member
  } do
    company_settings_fixture(company)

    Api.Settings.update_storyline_settings(
      storyline.id,
      %{
        main_color: "#FF0000",
        guides_settings: %{accent_color: "#AAAAAA"}
      },
      member
    )

    query_gql_by(:storyline,
      variables: %{"id" => storyline.id},
      context: context(member)
    )
    |> match_snapshot(scrub: ["id"])
  end

  test "query storylines settings with a different globalJs/globalCss", %{
    private_storyline: storyline,
    company: company,
    member: member
  } do
    company_settings_fixture(company)

    Api.Settings.update_storyline_settings(
      storyline.id,
      %{
        global_js: "window.alert('hi');",
        global_css: "body { background: red; }"
      },
      member
    )

    query_gql_by(:storyline,
      variables: %{"id" => storyline.id},
      context: context(member)
    )
    |> match_snapshot(scrub: ["id"])
  end
end
