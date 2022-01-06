defmodule ApiWeb.GraphQL.CollaboratorsTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :add_collaborator,
    ApiWeb.Schema,
    "test/support/mutations/AddCollaboratorToStoryline.gql"
  )

  load_gql(
    :remove_collaborator,
    ApiWeb.Schema,
    "test/support/mutations/RemoveCollaboratorFromStoryline.gql"
  )

  setup [:register_and_log_in_member]

  setup %{context: %{current_member: member}} do
    storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
    {:ok, storyline: storyline}
  end

  describe "AddCollaboratorToStoryline" do
    test "it should add a member to collaborators of a storyline", %{
      context: context,
      storyline: storyline,
      company: company
    } do
      new_user = Api.AccountsFixtures.user_fixture()
      {:ok, member2} = Api.Companies.add_member(new_user.id, company)

      assert {:ok, query_data} =
               query_gql_by(
                 :add_collaborator,
                 variables: %{"storylineId" => storyline.id, "memberId" => member2.id},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "addCollaboratorToStoryline"])

      assert result == %{
               "member" => %{"id" => member2.id},
               "storyline" => %{"id" => storyline.id}
             }
    end

    test "authorization", %{context: context, storyline: storyline, company: company} do
      new_user = Api.AccountsFixtures.user_fixture()
      {:ok, member2} = Api.Companies.add_member(new_user.id, company)

      TestAccess.assert_roles(
        &query_gql_by(
          :add_collaborator,
          variables: %{"storylineId" => storyline.id, "memberId" => member2.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end

  describe "RemoveCollaboratorFromStoryline" do
    test "it should add a remove a member from a storyline", %{
      context: context,
      storyline: storyline,
      company: company
    } do
      new_user = Api.AccountsFixtures.user_fixture()
      {:ok, member2} = Api.Companies.add_member(new_user.id, company)
      {:ok, _collab} = Api.Storylines.add_collaborator(storyline, member2.id, member2)

      assert {:ok, query_data} =
               query_gql_by(
                 :remove_collaborator,
                 variables: %{"storylineId" => storyline.id, "memberId" => member2.id},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "removeCollaboratorFromStoryline"])

      assert result == true
    end

    test "authorization", %{context: context, storyline: storyline, company: company} do
      new_user = Api.AccountsFixtures.user_fixture()
      {:ok, member2} = Api.Companies.add_member(new_user.id, company)
      {:ok, _collab} = Api.Storylines.add_collaborator(storyline, member2.id, member2)

      TestAccess.assert_roles(
        &query_gql_by(
          :remove_collaborator,
          variables: %{"storylineId" => storyline.id, "memberId" => member2.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
