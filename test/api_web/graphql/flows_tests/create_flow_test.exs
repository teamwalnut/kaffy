defmodule ApiWeb.GraphQL.CreateFlow do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :create_flow,
    ApiWeb.Schema,
    "test/support/mutations/flows/CreateFlow.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :get_default_flow
  ]

  describe "CreateFlow" do
    test "it creates a flow for a storyline", %{
      context: %{current_user: %{email: user_email}} = context,
      public_storyline: %{id: storyline_id} = storyline
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "flow_created",
                           %{flow: _flow_id, storyline: ^storyline_id} ->
        :ok
      end)

      flow_name = "My Flow"

      assert {:ok, query_data} =
               query_gql_by(
                 :create_flow,
                 variables: %{"storylineId" => storyline.id, "name" => flow_name},
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "createFlow"])

      assert result["id"] != nil
      assert result["name"] == flow_name
    end

    test "it doesn't create a flow if name is empty", %{
      context: context,
      public_storyline: storyline
    } do
      flow_name = ""

      assert {:ok, query_data} =
               query_gql_by(
                 :create_flow,
                 variables: %{"storylineId" => storyline.id, "name" => flow_name},
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Name can't be blank"
    end

    test "authorization", %{context: context, public_storyline: storyline} do
      TestAccess.assert_roles(
        &query_gql_by(
          :create_flow,
          variables: %{"storylineId" => storyline.id, "name" => "My Flow"},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
