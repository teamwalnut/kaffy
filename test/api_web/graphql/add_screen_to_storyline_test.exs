defmodule ApiWeb.GraphQL.AddScreenToStoryline do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :add_screen,
    ApiWeb.Schema,
    "test/support/mutations/AddScreenToStoryline.gql"
  )

  load_gql(
    :add_screen_with_dimensions,
    ApiWeb.Schema,
    "test/support/mutations/AddScreenWithDimensionsToStoryline.gql"
  )

  load_gql(
    :storyline,
    ApiWeb.Schema,
    "test/support/queries/Storyline.gql"
  )

  setup [:register_and_log_in_member]

  describe "addScreenToStoryline" do
    test "Fails to add screen to storyline with wrong member role", %{
      context: context,
      company: company
    } do
      admin_user = Api.AccountsFixtures.user_fixture()
      {:ok, admin_member} = Api.Companies.add_member(admin_user.id, company)
      %{id: storyline_id} = Api.StorylinesFixtures.public_storyline_fixture(admin_member)

      TestAccess.assert_roles(
        &query_gql_by(
          :add_screen,
          variables: %{
            "storylineId" => storyline_id,
            "screenshotImageUri" => "someURL",
            "name" => "name name",
            "url" => "some url",
            "s3ObjectName" => "nom_nom_nom"
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "Adds screen to storyline correctly", %{
      context: context,
      user: %{email: user_email},
      member: member
    } do
      %{id: storyline_id} = Api.StorylinesFixtures.public_storyline_fixture(member)

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "screen_added",
                           %{screen: _screen_id, storyline: ^storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :add_screen,
                 variables: %{
                   "storylineId" => storyline_id,
                   "screenshotImageUri" => "someURL",
                   "name" => "name name",
                   "url" => "some url",
                   "s3ObjectName" => "nom_nom_nom"
                 },
                 context: context
               )

      no_errors!(query_data)

      screen = get_in(query_data, [:data, "addScreenToStoryline"])
      assert screen["name"] == "name name"
      refute is_nil(screen["id"])

      assert {:ok, query_data} =
               query_gql_by(
                 :storyline,
                 variables: %{
                   "id" => storyline_id
                 },
                 context: context
               )

      no_errors!(query_data)
      storyline = get_in(query_data, [:data, "storyline"])

      assert storyline["screensCount"] == 1
      screens = get_in(query_data, [:data, "storyline", "screens"])
      assert screens == [%{"id" => screen["id"], "name" => screen["name"]}]
    end

    test "Can add dimensions to screen", %{context: context, member: member} do
      storyline = Api.StorylinesFixtures.public_storyline_fixture(member)

      assert {:ok, query_data} =
               query_gql_by(
                 :add_screen_with_dimensions,
                 variables: %{
                   "storylineId" => storyline.id,
                   "screenshotImageUri" => "someURL",
                   "name" => "name name",
                   "url" => "some url",
                   "s3ObjectName" => "nom_nom_nom",
                   "originalDimensions" => %{
                     "width" => 10,
                     "height" => 33
                   }
                 },
                 context: context
               )

      no_errors!(query_data)

      screen = get_in(query_data, [:data, "addScreenToStoryline"])
      assert screen["originalDimensions"] == %{"height" => 33, "width" => 10}
      refute is_nil(screen["id"])

      assert {:ok, query_data} =
               query_gql_by(
                 :storyline,
                 variables: %{
                   "id" => storyline.id
                 },
                 context: context
               )

      storyline = get_in(query_data, [:data, "storyline"])
      assert storyline["screensCount"] == 1
      screens = get_in(query_data, [:data, "storyline", "screens"])
      assert screens == [%{"id" => screen["id"], "name" => screen["name"]}]
    end
  end
end
