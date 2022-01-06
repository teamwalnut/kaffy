defmodule ApiWeb.GraphQL.ListAllDemos do
  use ApiWeb.GraphQLCase
  alias Api.Storylines.Demos
  alias Api.Storylines.Demos.Archive

  load_gql(ApiWeb.Schema, "test/support/queries/AllDemos.gql")

  setup [
    :register_and_log_in_user,
    :setup_company,
    :setup_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "ListAllDemos" do
    test "it lists all demos per user", %{
      context: context,
      public_storyline: storyline,
      member: member
    } do
      %{demo: _demo1} = storyline |> demo_fixture(member)
      %{demo: _demo2} = storyline |> demo_fixture(member)

      assert {:ok, query_data} =
               query_gql(
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      demos_result = get_in(query_data, [:data, "allDemos"])
      assert demos_result |> Enum.count() == 2
    end

    test "screen count works", %{
      context: context,
      public_storyline: storyline,
      member: member
    } do
      storyline |> screen_fixture()
      storyline |> screen_fixture()
      assert {:ok, %{demo: _}} = Demos.create_demo(storyline.id, %{name: "test demo"}, member)

      assert {:ok, query_data} =
               query_gql(
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      assert [demo_result] = get_in(query_data, [:data, "allDemos"])
      assert get_in(demo_result, ["activeVersion", "screensCount"]) == 3
    end

    test "hasActiveGuides", %{
      context: context,
      public_storyline: storyline,
      member: member
    } do
      storyline |> screen_fixture()
      storyline |> screen_fixture()
      assert {:ok, %{demo: _}} = Demos.create_demo(storyline.id, %{name: "test demo"}, member)

      assert {:ok, query_data} =
               query_gql(
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      assert [demo_result] = get_in(query_data, [:data, "allDemos"])
      assert get_in(demo_result, ["activeVersion", "hasActiveGuides"]) == false
    end

    test "hasActiveGuides when true", %{
      context: context,
      public_storyline: storyline,
      member: member
    } do
      screen = storyline |> screen_fixture()
      storyline |> screen_fixture()
      guide = storyline |> guide_fixture()
      annotation_modal_fixture(guide, screen.id, member)
      assert {:ok, %{demo: _}} = Demos.create_demo(storyline.id, %{name: "test demo"}, member)

      assert {:ok, query_data} =
               query_gql(
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      assert [demo_result] = get_in(query_data, [:data, "allDemos"])
      assert get_in(demo_result, ["activeVersion", "hasActiveGuides"]) == true
    end

    test "it lists all archived demos per user", %{
      context: context,
      public_storyline: storyline,
      member: member
    } do
      %{demo: demo1} = storyline |> demo_fixture(member)
      %{demo: _demo2} = storyline |> demo_fixture(member)

      {:ok, _} = Archive.archive(demo1, member)

      assert {:ok, query_data} =
               query_gql(
                 variables: %{"isArchived" => true},
                 context: context
               )

      no_errors!(query_data)
      demos_result = get_in(query_data, [:data, "allDemos"])
      assert demos_result |> Enum.count() == 1
    end
  end
end
