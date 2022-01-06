defmodule ApiWeb.GraphQL.DeleteEditsInScreenTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess
  load_gql(ApiWeb.Schema, "test/support/mutations/DeleteEditsInScreen.gql")
  setup [:register_and_log_in_member]

  describe "deleteEditsInScreen" do
    test "it should delete edits successfully", %{
      context: %{current_user: %{email: user_email}, current_member: member} = context
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 2, fn ^user_email, type, _attrs ->
        if type |> String.ends_with?("_edit_deleted"), do: :ok, else: :error
      end)

      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      edit1 =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "original",
          :text => "new test"
        })

      edit2 =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "original",
          :text => "new test"
        })

      result =
        query_gql(
          variables: %{
            "screenId" => screen.id,
            "edits" => [%{"id" => edit1.id}, %{"id" => edit2.id}]
          },
          context: context
        )

      assert {:ok, query_data} = result
      no_errors!(query_data)
    end

    test "authorization", %{
      context: %{current_member: member} = context
    } do
      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      edit1 =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "original",
          :text => "new test"
        })

      edit2 =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "original",
          :text => "new test"
        })

      TestAccess.assert_roles(
        &query_gql(
          variables: %{
            "screenId" => screen.id,
            "edits" => [%{"id" => edit1.id}, %{"id" => edit2.id}]
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
