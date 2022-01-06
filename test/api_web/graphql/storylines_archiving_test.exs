defmodule ApiWeb.GraphQL.StorylineArchivingTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines.Archived
  alias Api.TestAccess

  load_gql(
    :archive_storyline,
    ApiWeb.Schema,
    "test/support/mutations/ArchiveStoryline.gql"
  )

  load_gql(
    :restore_storyline,
    ApiWeb.Schema,
    "test/support/mutations/RestoreStoryline.gql"
  )

  load_gql(
    :list_storylines,
    ApiWeb.Schema,
    "test/support/queries/Storylines.gql"
  )

  setup [:register_and_log_in_member]

  setup %{context: %{current_member: member}} do
    storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
    {:ok, storyline: storyline}
  end

  describe "Storyline/Archive" do
    test "Can archive a storyline successfully", %{
      storyline: storyline,
      context: %{current_user: _user} = context
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :archive_storyline,
                 variables: %{"storylineId" => storyline.id},
                 context: context
               )

      no_errors!(query_data)
      got_storyline = get_in(query_data, [:data, "archiveStoryline"])

      assert %{
               "collaborators" => [],
               "id" => storyline.id,
               "name" => storyline.name,
               "archivedAt" => got_storyline["archivedAt"]
             } ==
               got_storyline

      refute is_nil(got_storyline["archivedAt"])
    end

    test "Authorize archiving correctly", %{
      storyline: storyline,
      context: context
    } do
      TestAccess.assert_roles(
        &query_gql_by(
          :archive_storyline,
          variables: %{"storylineId" => storyline.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "Can restore a storyline successfully", %{
      storyline: storyline,
      context: %{current_member: actor} = context
    } do
      {:ok, _} = Archived.archive(storyline, actor)

      assert {:ok, query_data} =
               query_gql_by(
                 :restore_storyline,
                 variables: %{"storylineId" => storyline.id},
                 context: context
               )

      no_errors!(query_data)
      got_storyline = get_in(query_data, [:data, "restoreStoryline"])

      assert %{
               "isPublic" => storyline.is_public,
               "id" => storyline.id,
               "name" => storyline.name,
               "archivedAt" => nil
             } ==
               got_storyline
    end

    test "Authorize restoring correctly", %{
      storyline: storyline,
      context: %{current_member: actor} = context
    } do
      {:ok, _} = Archived.archive(storyline, actor)

      TestAccess.assert_roles(
        &query_gql_by(
          :restore_storyline,
          variables: %{"storylineId" => storyline.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "Can list archived storylines", %{
      storyline: storyline,
      context: %{current_member: actor} = context
    } do
      {:ok, %{archived_storyline: storyline}} = Archived.archive(storyline, actor)

      assert {:ok, query_data} =
               query_gql_by(
                 :list_storylines,
                 variables: %{"isArchived" => true},
                 context: context
               )

      no_errors!(query_data)

      got_storyline =
        get_in(query_data, [:data, "storylines"])
        |> Enum.at(0)
        |> Map.drop(["lastEdited", "owner"])

      storyline = storyline |> Api.Repo.preload(:flows)

      default_flow =
        storyline.flows |> Enum.at(0) |> Api.Repo.preload(:screens) |> map_flow_to_gql_struct

      assert %{
               "isPublic" => storyline.is_public,
               "id" => storyline.id,
               "collaborators" => [],
               "screensCount" => 0,
               "archivedAt" => got_storyline["archivedAt"],
               "flows" => [default_flow],
               "patches" => []
             } ==
               got_storyline

      refute is_nil(got_storyline["archivedAt"])
    end
  end
end
