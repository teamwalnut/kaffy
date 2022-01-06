defmodule ApiWeb.GraphQL.UpdateStorylineTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :update_storyline,
    ApiWeb.Schema,
    "test/support/mutations/UpdateStoryline.gql"
  )

  setup [:register_and_log_in_member]

  describe "updateStoryline" do
    setup %{context: %{current_member: member}} do
      storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
      {:ok, storyline: storyline}
    end

    test "it should update the storyline name", %{context: context, storyline: storyline} do
      %{current_user: %{email: user_email}} = context

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "storyline_updated",
                           %{url: "https://app.teamwalnut.com/storylines/" <> _storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_storyline,
                 variables: %{"storylineId" => storyline.id, "name" => "#{storyline.name}11!"},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "updateStoryline", "name"])
      assert result == "#{storyline.name}11!"
    end

    test "it should set the start screen correctly", %{context: context, storyline: storyline} do
      %{current_user: %{email: user_email}} = context

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "storyline_updated",
                           %{url: "https://app.teamwalnut.com/storylines/" <> _storyline_id} ->
        :ok
      end)

      _screen = Api.StorylinesFixtures.screen_fixture(storyline)
      screen2 = Api.StorylinesFixtures.screen_fixture(storyline)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_storyline,
                 variables: %{"storylineId" => storyline.id, "startScreenId" => screen2.id},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "updateStoryline", "startScreen"])
      assert result["id"] == screen2.id
    end

    test "it should set storyline isPublic flag", %{context: context, storyline: storyline} do
      %{current_user: %{email: user_email}} = context

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "storyline_updated",
                           %{url: "https://app.teamwalnut.com/storylines/" <> _storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_storyline,
                 variables: %{"storylineId" => storyline.id, "isPublic" => false},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "updateStoryline", "isPublic"])
      assert result == false
    end

    test "authorization", %{context: context, storyline: storyline} do
      TestAccess.assert_roles(
        &query_gql_by(
          :update_storyline,
          variables: %{"storylineId" => storyline.id, "name" => "#{storyline.name}11!"},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end

  describe "updateStoryline (private storyline)" do
    test "authorization (owner)", %{context: context} do
      storyline = Api.StorylinesFixtures.private_storyline_fixture(context.current_member)

      TestAccess.assert_roles(
        &query_gql_by(
          :update_storyline,
          variables: %{"storylineId" => storyline.id, "name" => "#{storyline.name}11!"},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "authorization (non-owner)", %{context: context, company: company} do
      user = Api.AccountsFixtures.user_fixture()
      {:ok, other_member} = Api.Companies.add_member(user.id, company)
      storyline = Api.StorylinesFixtures.private_storyline_fixture(other_member)

      TestAccess.assert_roles(
        &query_gql_by(
          :update_storyline,
          variables: %{"storylineId" => storyline.id, "name" => "#{storyline.name}11!"},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: false, editor: false, company_admin: false}
      )
    end
  end
end
