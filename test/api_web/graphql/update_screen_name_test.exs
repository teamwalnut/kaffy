defmodule ApiWeb.GraphQL.UpdateScreenNameTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(ApiWeb.Schema, "test/support/mutations/UpdateScreenName.gql")
  setup [:register_and_log_in_member]

  describe "updateScreenName" do
    test "it should update the screen name", %{
      context: %{current_user: %{email: user_email}, current_member: member} = context
    } do
      storyline = %{id: storyline_id} = Api.StorylinesFixtures.public_storyline_fixture(member)
      screen = %{id: screen_id} = Api.StorylinesFixtures.screen_fixture(storyline)

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "screen_renamed",
                           %{screen: ^screen_id, storyline: ^storyline_id} ->
        :ok
      end)

      result =
        query_gql(
          variables: %{"id" => screen.id, "name" => "#{screen.name} more NAME"},
          context: context
        )

      {:ok, query_data} = result
      no_errors!(query_data)

      result = get_in(query_data, [:data, "updateScreenName", "name"])
      assert result == "#{screen.name} more NAME"
    end

    test "authorization", %{context: %{current_member: member} = context} do
      storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
      screen = Api.StorylinesFixtures.screen_fixture(storyline)

      TestAccess.assert_roles(
        &query_gql(
          variables: %{"id" => screen.id, "name" => "#{screen.name} more NAME"},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
