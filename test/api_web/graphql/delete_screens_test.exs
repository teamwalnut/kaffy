defmodule ApiWeb.GraphQL.DeleteScreensTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines
  alias Api.TestAccess

  load_gql(:delete_screens, ApiWeb.Schema, "test/support/mutations/DeleteScreens.gql")
  load_gql(:storyline, ApiWeb.Schema, "test/support/queries/Storyline.gql")

  setup [:register_and_log_in_member]

  test "delete a single screen", %{context: context} do
    storyline =
      %{id: storyline_id} =
      Api.StorylinesFixtures.public_storyline_fixture(context.current_member)

    Api.StorylinesFixtures.screen_fixture(storyline, %{name: "First screen"})

    %{id: deleted_screen_id} =
      Api.StorylinesFixtures.screen_fixture(storyline, %{name: "Deleted screen"})

    user_email = context.current_member.user.email
    screen_ids = [deleted_screen_id]

    ApiWeb.Analytics.ProviderMock
    |> expect(:track, fn
      ^user_email, "screens_deleted", %{screen_ids: ^screen_ids, storyline_id: ^storyline_id} ->
        :ok
    end)

    query_gql_by(:delete_screens,
      variables: %{"storylineId" => storyline_id, "screenIds" => screen_ids},
      context: context
    )
    |> match_snapshot(variation: "mutation", scrub: ["id", "lastEdited"])

    query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
    |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
  end

  test "deleting screen should update storyline last updated", %{context: context, member: member} do
    storyline = %{id: storyline_id} = Api.StorylinesFixtures.public_storyline_fixture(member)

    Api.StorylinesFixtures.screen_fixture(storyline, %{name: "First screen"})

    %{id: deleted_screen_id} =
      Api.StorylinesFixtures.screen_fixture(storyline, %{name: "Deleted screen"})

    time_before_deleting = DateTime.utc_now()
    screen_ids = [deleted_screen_id]

    query_gql_by(:delete_screens,
      variables: %{"storylineId" => storyline_id, "screenIds" => screen_ids},
      context: context
    )

    storyline = Storylines.get_storyline!(storyline.id)
    assert DateTime.compare(storyline.last_edited, time_before_deleting) == :gt
  end

  test "delete multiple screens", %{context: context} do
    storyline =
      %{id: storyline_id} =
      Api.StorylinesFixtures.public_storyline_fixture(context.current_member)

    %{id: first_screen_id} = Api.StorylinesFixtures.screen_fixture(storyline)
    %{id: second_screen_id} = Api.StorylinesFixtures.screen_fixture(storyline)
    user_email = context.current_member.user.email
    screen_ids = [first_screen_id, second_screen_id]

    ApiWeb.Analytics.ProviderMock
    |> expect(:track, fn
      ^user_email, "screens_deleted", %{screen_ids: ^screen_ids, storyline_id: ^storyline_id} ->
        :ok
    end)

    query_gql_by(:delete_screens,
      variables: %{"storylineId" => storyline_id, "screenIds" => screen_ids},
      context: context
    )
    |> match_snapshot(variation: "mutation", scrub: ["id", "lastEdited"])

    query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
    |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
  end

  test "authorization", %{context: context} do
    storyline =
      %{id: storyline_id} =
      Api.StorylinesFixtures.public_storyline_fixture(context.current_member)

    %{id: first_screen_id} = Api.StorylinesFixtures.screen_fixture(storyline)
    %{id: second_screen_id} = Api.StorylinesFixtures.screen_fixture(storyline)
    screen_ids = [first_screen_id, second_screen_id]

    TestAccess.assert_roles(
      &query_gql_by(
        :delete_screens,
        variables: %{"storylineId" => storyline_id, "screenIds" => screen_ids},
        context: Map.put(context, :current_member, &1)
      ),
      context.current_member,
      %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
    )
  end
end
