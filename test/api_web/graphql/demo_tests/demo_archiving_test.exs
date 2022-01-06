defmodule ApiWeb.GraphQL.DemoArchivingTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines.Demos.Archive
  alias Api.TestAccess

  load_gql(
    :archive_demo,
    ApiWeb.Schema,
    "test/support/mutations/demos/ArchiveDemo.gql"
  )

  load_gql(
    :restore_demo,
    ApiWeb.Schema,
    "test/support/mutations/demos/RestoreDemo.gql"
  )

  load_gql(ApiWeb.Schema, "test/support/queries/Demos.gql")

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_demo
  ]

  describe "Demo/Archive" do
    test "Can archive a demo successfully", %{
      context: context,
      demo: demo
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :archive_demo,
                 variables: %{"id" => demo.id},
                 context: context
               )

      no_errors!(query_data)
      demo_result = get_in(query_data, [:data, "archiveDemo"])

      assert %{
               "id" => demo.id,
               "name" => demo.name,
               "archivedAt" => demo_result["archivedAt"]
             } ==
               demo_result

      refute is_nil(demo_result["archivedAt"])
    end

    test "Can restore a demo successfully", %{
      context: %{current_member: actor} = context,
      demo: demo
    } do
      {:ok, _} = Archive.archive(demo, actor)

      assert {:ok, query_data} =
               query_gql_by(
                 :restore_demo,
                 variables: %{"id" => demo.id},
                 context: context
               )

      no_errors!(query_data)
      demo_result = get_in(query_data, [:data, "restoreDemo"])

      assert %{
               "id" => demo.id,
               "name" => demo.name,
               "archivedAt" => nil
             } ==
               demo_result
    end

    test "authorize restore demo", %{context: %{current_member: actor} = context, demo: demo} do
      {:ok, _} = Archive.archive(demo, actor)

      TestAccess.assert_roles(
        &query_gql_by(
          :restore_demo,
          variables: %{"id" => demo.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "Can list archived demos", %{
      context: %{current_member: actor} = context,
      public_storyline: %{id: storyline_id} = storyline,
      member: member
    } do
      %{demo: demo} = storyline |> demo_fixture(member)
      %{demo: _demo2} = storyline |> demo_fixture(member)

      {:ok, archived_demo} = Archive.archive(demo, actor)

      assert {:ok, query_data} =
               query_gql(
                 variables: %{"isArchived" => true, "storylineId" => storyline_id},
                 context: context
               )

      no_errors!(query_data)

      demo_results = get_in(query_data, [:data, "demos"])
      assert demo_results |> Enum.count() == 1

      demo_result = demo_results |> Enum.at(0)
      assert demo_result["id"] == archived_demo.id
      refute is_nil(demo_result["archivedAt"])
    end
  end
end
