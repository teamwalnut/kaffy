defmodule ApiWeb.GraphQL.RenameDemo do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :rename_demo,
    ApiWeb.Schema,
    "test/support/mutations/demos/RenameDemo.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_demo
  ]

  describe "RenameDemo" do
    test "it renames a demo", %{
      context: %{current_user: %{email: user_email}} = context,
      demo: %{id: demo_id} = demo,
      public_storyline: %{id: storyline_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "demo_renamed",
                           %{demo: ^demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      demo_name = "My Demo"

      assert {:ok, query_data} =
               query_gql_by(
                 :rename_demo,
                 variables: %{"demoId" => demo.id, "name" => demo_name},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "renameDemo"])

      assert result["id"] != nil
      assert result["name"] == demo_name
    end

    test "it doesn't renames a demo if the name is empty", %{
      context: context,
      demo: demo
    } do
      demo_name = ""

      assert {:ok, query_data} =
               query_gql_by(
                 :rename_demo,
                 variables: %{"demoId" => demo.id, "name" => demo_name},
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Name can't be blank"
    end

    test "authorization", %{
      context: context,
      demo: demo
    } do
      demo_name = "My Demo"

      TestAccess.assert_roles(
        &query_gql_by(
          :rename_demo,
          variables: %{"demoId" => demo.id, "name" => demo_name},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
