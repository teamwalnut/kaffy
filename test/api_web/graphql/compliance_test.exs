defmodule ApiWeb.GraphQL.ComplianceTest do
  use ApiWeb.GraphQLCase

  load_gql(
    :read_compliance,
    ApiWeb.Schema,
    "test/support/queries/Compliance.gql"
  )

  load_gql(
    :approve_tac,
    ApiWeb.Schema,
    "test/support/mutations/ApproveTac.gql"
  )

  setup [:verify_on_exit!, :register_and_log_in_user]

  describe "compliance" do
    test "it should fail if the user in unauthenticated" do
      {:ok, res} = query_gql_by(:read_compliance)
      assert unauthorized_error(res)
    end

    test "it should return nil if the user hasn't approve to tac yet", %{context: context} do
      {:ok, res} = query_gql_by(:read_compliance, context: context)
      no_errors!(res)
      assert res == %{data: %{"compliance" => %{"isTacApproved" => false}}}
    end

    test "it should be able to approve tac", %{context: context} do
      {:ok, res} = query_gql_by(:approve_tac, context: context)
      no_errors!(res)

      {:ok, res} = query_gql_by(:read_compliance, context: context)
      no_errors!(res)

      assert res == %{data: %{"compliance" => %{"isTacApproved" => true}}}
    end
  end
end
