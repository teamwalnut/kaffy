defmodule ApiWeb.GraphQL.CompanyTest do
  use ApiWeb.GraphQLCase

  load_gql(:current_company, ApiWeb.Schema, "test/support/queries/CurrentCompany.gql")
  load_gql(:company, ApiWeb.Schema, "test/support/queries/Company.gql")

  describe "CurrentCompany (logged out)" do
    test "should return nil and error" do
      assert capture_log(fn ->
               result = query_gql_by(:current_company)
               assert {:ok, query_data} = result

               company = get_in(query_data, [:data, "currentCompany"])
               assert is_nil(company)

               error = get_in(query_data, [:errors]) |> Enum.at(0)

               assert error[:message] == "Unauthorized"
             end) =~ "Tried to access protected resource without permissions"
    end
  end

  describe "CurrentCompany (logged in)" do
    setup [:register_and_log_in_member]

    test "should return the current company", %{context: context} do
      result = query_gql_by(:current_company, variables: %{}, context: context)
      assert {:ok, query_data} = result

      company = get_in(query_data, [:data, "currentCompany"])
      assert String.starts_with?(get_in(company, ["name"]), "company_")

      members = get_in(company, ["members"])
      assert Enum.count(members) == 1

      errors = get_in(query_data, [:errors])
      refute errors
    end
  end

  describe "CurrentCompany (logged in) with MemberInvites" do
    setup [:register_and_log_in_member]

    setup %{member: member} do
      Api.MemberInvite.invite_member("paz1@walut.io", member, :editor)
      Api.MemberInvite.invite_member("paz2@walut.io", member, :viewer)

      %{}
    end

    test "should return the current company with member invites, ordered by inserted_at DESC", %{
      context: context
    } do
      result = query_gql_by(:current_company, variables: %{}, context: context)
      assert {:ok, query_data} = result

      company = get_in(query_data, [:data, "currentCompany"])
      assert String.starts_with?(get_in(company, ["name"]), "company_")

      members = get_in(company, ["memberInvites"])
      assert Enum.count(members) == 2
      assert Enum.at(members, 0)["email"] == "paz2@walut.io"
      assert Enum.at(members, 0)["role"] == "VIEWER"

      assert Enum.at(members, 1)["email"] == "paz1@walut.io"
      assert Enum.at(members, 1)["role"] == "EDITOR"

      errors = get_in(query_data, [:errors])
      refute errors
    end
  end

  describe "Company" do
    setup [:register_and_log_in_member]

    test "should return the company", %{context: context, company: company} do
      query_gql_by(:company, variables: %{"id" => company.id}, context: context)
      |> match_snapshot(scrub: ["id"])
    end
  end
end
