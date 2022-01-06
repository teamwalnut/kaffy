defmodule ApiWeb.GraphQL.GetDemo do
  use ApiWeb.GraphQLCase
  load_gql(ApiWeb.Schema, "test/support/queries/Demo.gql")

  setup [
    :register_and_log_in_user,
    :setup_company,
    :setup_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_storyline_html_patch,
    :setup_guide,
    :setup_point_annotation,
    :setup_modal_annotation
  ]

  describe "Demo" do
    test "gets single demo by id", %{
      context: context,
      public_storyline: storyline,
      user: user,
      member: member
    } do
      demo_name = "demo name"
      %{demo: demo} = storyline |> demo_fixture(member, %{name: demo_name})

      assert {:ok, query_data} = query_gql(variables: %{"id" => demo.id}, context: context)
      no_errors!(query_data)

      demo_result = get_in(query_data, [:data, "demo"])
      assert demo_result["id"] == demo.id
      assert demo_result["name"] == demo_name
      assert demo_result["isShared"] == true
      assert demo_result["lastPlayed"] == nil

      storyline_result = get_in(query_data, [:data, "demo", "storyline"])
      assert storyline_result["id"] == storyline.id

      active_version_result = get_in(query_data, [:data, "demo", "activeVersion"])
      assert active_version_result["createdBy"]["id"] == member.id
      assert active_version_result["createdBy"]["user"]["firstName"] == user.first_name
      assert active_version_result["createdBy"]["user"]["lastName"] == user.last_name
      assert active_version_result["flows"] == []
      assert active_version_result["guides"] == []
      assert active_version_result["patches"] == []
      assert active_version_result["startScreen"]["id"] == storyline.start_screen_id
    end
  end
end
