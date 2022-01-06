defmodule ApiWeb.GraphQL.RenameGuide do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :rename_guide,
    ApiWeb.Schema,
    "test/support/mutations/annotations/RenameGuide.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_guide
  ]

  describe "RenameGuide" do
    test "it renames a guide when called with a valid name", %{
      context: %{current_user: %{email: user_email}} = context,
      guide: guide
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email, "guide_renamed", %{guide: _guide_id} ->
        :ok
      end)

      new_guide_name = "New guide name"

      assert {:ok, query_data} =
               query_gql_by(
                 :rename_guide,
                 variables: %{"id" => guide.id, "name" => new_guide_name},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "renameGuide"])

      assert result["name"] == new_guide_name
    end

    test "it doesn't rename a guide when called with an invalid name", %{
      context: context,
      guide: guide
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :rename_guide,
                 variables: %{"id" => guide.id, "name" => nil},
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Argument \"name\" has invalid value $name."
    end

    test "authorization", %{context: context, guide: guide} do
      new_guide_name = "New guide name"

      TestAccess.assert_roles(
        &query_gql_by(
          :rename_guide,
          variables: %{"id" => guide.id, "name" => new_guide_name},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
