defmodule ApiWeb.GraphQL.DeleteFlow do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :delete_flow,
    ApiWeb.Schema,
    "test/support/mutations/flows/DeleteFlow.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :get_default_flow,
    :setup_flow
  ]

  describe "DeleteFlow" do
    test "it deletes the flow from the storyline", %{
      context: %{current_user: %{email: user_email}} = context,
      flow: %{id: flow_id} = flow,
      public_storyline: %{id: storyline_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "flow_deleted",
                           %{flow: ^flow_id, storyline: ^storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :delete_flow,
                 variables: %{"flowId" => flow.id},
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "deleteFlow"])
      assert result["id"] == flow.id
    end

    test "it doesn't delete the flow if it's a default flow", %{
      context: context,
      default_flow: default_flow
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 0, fn _, "flow_deleted", _ -> :ok end)

      assert {:ok, query_data} =
               query_gql_by(
                 :delete_flow,
                 variables: %{"flowId" => default_flow.id},
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Failed to delete flow " <> default_flow.id
    end

    test "authorization", %{context: context, flow: flow} do
      TestAccess.assert_roles(
        &query_gql_by(
          :delete_flow,
          variables: %{"flowId" => flow.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
