defmodule ApiWeb.GraphQL.RenameFlow do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :rename_flow,
    ApiWeb.Schema,
    "test/support/mutations/flows/RenameFlow.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :get_default_flow,
    :setup_flow
  ]

  describe "RenameFlow" do
    test "it renames a flow", %{
      context: %{current_user: %{email: user_email}} = context,
      flow: %{id: flow_id} = flow,
      public_storyline: %{id: storyline_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "flow_renamed",
                           %{flow: ^flow_id, storyline: ^storyline_id} ->
        :ok
      end)

      flow_name = "My Flow"

      assert {:ok, query_data} =
               query_gql_by(
                 :rename_flow,
                 variables: %{"flowId" => flow.id, "name" => flow_name},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "renameFlow"])

      assert result["id"] != nil
      assert result["name"] == flow_name
    end

    test "it doesn't renames a flow if the name is empty", %{
      context: context,
      flow: flow
    } do
      flow_name = ""

      assert {:ok, query_data} =
               query_gql_by(
                 :rename_flow,
                 variables: %{"flowId" => flow.id, "name" => flow_name},
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Name can't be blank"
    end

    test "authorization", %{
      context: context,
      flow: flow
    } do
      TestAccess.assert_roles(
        &query_gql_by(
          :rename_flow,
          variables: %{"flowId" => flow.id, "name" => "My Flow"},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
