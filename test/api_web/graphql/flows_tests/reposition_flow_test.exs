defmodule ApiWeb.GraphQL.RepositionFlow do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :reposition_flow,
    ApiWeb.Schema,
    "test/support/mutations/flows/RepositionFlow.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :get_default_flow,
    :setup_multiple_flows
  ]

  describe "RepositionFlow" do
    test "it reposition flow up and returns the updated flows", %{
      context: context,
      flows: flows
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_flow,
                 variables: %{"flowId" => Enum.at(flows, 0).id, "newPosition" => 3},
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "repositionFlow"])

      assert result == [
               %{
                 "id" => Enum.at(flows, 1).id,
                 "isDefault" => false,
                 "position" => 2
               },
               %{
                 "id" => Enum.at(flows, 0).id,
                 "isDefault" => false,
                 "position" => 3
               }
             ]
    end

    test "it reposition flow down and returns the updated flows", %{
      context: context,
      flows: flows
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_flow,
                 variables: %{"flowId" => Enum.at(flows, 2).id, "newPosition" => 2},
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "repositionFlow"])

      assert result == [
               %{
                 "id" => Enum.at(flows, 2).id,
                 "isDefault" => false,
                 "position" => 2
               },
               %{
                 "id" => Enum.at(flows, 0).id,
                 "isDefault" => false,
                 "position" => 3
               },
               %{
                 "id" => Enum.at(flows, 1).id,
                 "isDefault" => false,
                 "position" => 4
               }
             ]
    end

    test "it doesn't reposition a flow if current position equals new position", %{
      context: context,
      flows: flows
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_flow,
                 variables: %{"flowId" => Enum.at(flows, 1).id, "newPosition" => 3},
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "repositionFlow"])

      assert result == [
               %{
                 "id" => Enum.at(flows, 1).id,
                 "isDefault" => false,
                 "position" => 3
               }
             ]
    end

    test "it logs a warning if changeset errors were raised", %{
      context: context,
      default_flow: default_flow
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_flow,
                 variables: %{"flowId" => default_flow.id, "newPosition" => 2},
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Something went wrong"
    end

    test "authorization", %{context: context, flows: flows} do
      TestAccess.assert_roles(
        &query_gql_by(
          :reposition_flow,
          variables: %{"flowId" => Enum.at(flows, 0).id, "newPosition" => 3},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
