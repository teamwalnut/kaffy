defmodule ApiWeb.GraphQL.ListDemos do
  use ApiWeb.GraphQLCase
  alias Api.Storylines.Demos.Archive

  load_gql(ApiWeb.Schema, "test/support/queries/Demos.gql")

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "ListDemos" do
    test "it lists all demos for a storyline", %{
      context: context,
      public_storyline: %{id: storyline_id} = storyline,
      member: member
    } do
      %{demo: _demo1} = storyline |> demo_fixture(member)
      %{demo: _demo2} = storyline |> demo_fixture(member)

      assert {:ok, query_data} =
               query_gql(variables: %{"storylineId" => storyline_id}, context: context)

      no_errors!(query_data)
      demos_result = get_in(query_data, [:data, "demos"])
      assert demos_result |> Enum.count() == 2
    end

    test "it lists all archived demos for a storyline", %{
      context: context,
      public_storyline: %{id: storyline_id} = storyline,
      member: member
    } do
      %{demo: demo1} = storyline |> demo_fixture(member)
      %{demo: _demo2} = storyline |> demo_fixture(member)

      assert {:ok, demo1} = Archive.archive(demo1, member)

      assert {:ok, query_data} =
               query_gql(
                 variables: %{"storylineId" => storyline_id, "isArchived" => true},
                 context: context
               )

      no_errors!(query_data)
      demos_result = get_in(query_data, [:data, "demos"])
      assert demos_result |> Enum.count() == 1

      Archive.restore(demo1, member)

      assert {:ok, query_data} =
               query_gql(
                 variables: %{"storylineId" => storyline_id, "isArchived" => true},
                 context: context
               )

      no_errors!(query_data)
      demos_result = get_in(query_data, [:data, "demos"])
      assert demos_result |> Enum.count() == 0
    end
  end
end
