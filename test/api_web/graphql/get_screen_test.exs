defmodule ApiWeb.GraphQL.GetScreenTest do
  use ApiWeb.GraphQLCase
  load_gql(ApiWeb.Schema, "test/support/queries/GetScreenById.gql")
  setup [:register_and_log_in_member]

  describe "screenQuery" do
    test "it should return the screen attributes", %{context: context, member: member} do
      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      require Logger

      result =
        query_gql(
          variables: %{"storylineId" => screen.storyline_id, "screenId" => screen.id},
          context: context
        )

      assert {:ok, query_data} = result
      no_errors!(query_data)

      result = get_in(query_data, [:data, "screen"])
      assert result["id"] == screen.id
    end

    test "can get a screen on a private storyline when owner", %{company: company} do
      user = Api.AccountsFixtures.user_fixture()
      {:ok, owner} = Api.Companies.add_member(user.id, company, %{role: :editor})

      screen =
        Api.StorylinesFixtures.private_storyline_fixture(owner)
        |> Api.StorylinesFixtures.screen_fixture()

      {:ok, res} =
        query_gql(
          variables: %{"storylineId" => screen.storyline_id, "screenId" => screen.id},
          context: %{current_member: owner}
        )

      assert no_errors!(res)
    end

    test "can get a screen on a private storyline when collaborator", %{
      member: member,
      company: company
    } do
      user = Api.AccountsFixtures.user_fixture()
      {:ok, collaborator} = Api.Companies.add_member(user.id, company, %{role: :editor})

      storyline = Api.StorylinesFixtures.private_storyline_fixture(member)
      {:ok, _} = Api.Storylines.add_collaborator(storyline, collaborator.id, member)
      screen = storyline |> Api.StorylinesFixtures.screen_fixture()

      {:ok, res} =
        query_gql(
          variables: %{"storylineId" => screen.storyline_id, "screenId" => screen.id},
          context: %{current_member: member}
        )

      assert no_errors!(res)
    end

    test "cannot get a screen when not a collaborator or owner on a private storyline", %{
      company: company,
      member: member
    } do
      user = Api.AccountsFixtures.user_fixture()
      {:ok, non_owner} = Api.Companies.add_member(user.id, company, %{role: :viewer})

      screen =
        Api.StorylinesFixtures.private_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      {:ok, res} =
        query_gql(
          variables: %{"storylineId" => screen.storyline_id, "screenId" => screen.id},
          context: %{current_member: non_owner}
        )

      assert unauthorized_error(res)
    end

    test "cannot get a screen from another company", %{context: context} do
      user = Api.AccountsFixtures.user_fixture()
      %{member: outside_company_member} = Api.CompaniesFixtures.company_and_member_fixture(user)

      screen =
        Api.StorylinesFixtures.public_storyline_fixture(outside_company_member)
        |> Api.StorylinesFixtures.screen_fixture()

      {:ok, res} =
        query_gql(
          variables: %{"storylineId" => screen.storyline_id, "screenId" => screen.id},
          context: context
        )

      assert unauthorized_error(res)
    end
  end
end
