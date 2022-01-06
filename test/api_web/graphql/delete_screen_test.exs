defmodule ApiWeb.GraphQL.DeleteScreenTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(ApiWeb.Schema, "test/support/mutations/DeleteScreen.gql")
  setup [:register_and_log_in_member]

  describe "deleteScreen" do
    test "it should succeed if not firstScreen", %{
      context: %{current_user: %{email: user_email}, current_member: member} = context
    } do
      storyline = %{id: storyline_id} = Api.StorylinesFixtures.public_storyline_fixture(member)
      _screen = Api.StorylinesFixtures.screen_fixture(storyline)
      screen2 = %{id: screen_id} = Api.StorylinesFixtures.screen_fixture(storyline)

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "screen_deleted",
                           %{screen: ^screen_id, storyline: ^storyline_id} ->
        :ok
      end)

      result =
        query_gql(
          variables: %{"id" => screen2.id},
          context: context
        )

      {:ok, query_data} = result
      no_errors!(query_data)
    end

    test "authorization", %{
      context: %{current_member: member} = context
    } do
      storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
      _screen = Api.StorylinesFixtures.screen_fixture(storyline)
      screen2 = Api.StorylinesFixtures.screen_fixture(storyline)

      TestAccess.assert_roles(
        &query_gql(
          variables: %{"id" => screen2.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
