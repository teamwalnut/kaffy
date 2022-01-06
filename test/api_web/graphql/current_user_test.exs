defmodule ApiWeb.GraphQL.CurrentUserTest do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/CurrentUser.gql")

  describe "CurrentUser" do
    setup [:register_and_log_in_user, :setup_company, :setup_member]

    test "Without login, should return nil and error" do
      assert capture_log(fn ->
               result = query_gql()
               assert {:ok, query_data} = result

               current_user = get_in(query_data, [:data, "currentUser"])
               assert is_nil(current_user)

               error = get_in(query_data, [:errors]) |> Enum.at(0)

               assert error[:message] == "Unauthorized"
             end) =~ "Tried to access protected resource without permissions"
    end

    test "It should return members", %{context: context, member: member, company: company} do
      result = query_gql(variables: %{}, context: context)
      assert {:ok, query_data} = result

      current_user = get_in(query_data, [:data, "currentUser"])
      assert current_user["members"] == [%{"id" => member.id, "role" => "COMPANY_ADMIN"}]
      assert current_user["companies"] == [%{"id" => company.id}]

      errors = get_in(query_data, [:errors])
      refute errors
    end

    test "After login, should return the current user", %{context: context} do
      result = query_gql(variables: %{}, context: context)
      assert {:ok, query_data} = result

      user_first_name = get_in(query_data, [:data, "currentUser", "firstName"])
      assert user_first_name == "my name is"

      errors = get_in(query_data, [:errors])
      refute errors
    end
  end
end
