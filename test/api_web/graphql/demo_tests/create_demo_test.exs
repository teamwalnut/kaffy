defmodule ApiWeb.GraphQL.CreateDemo do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :create_demo,
    ApiWeb.Schema,
    "test/support/mutations/demos/CreateDemo.gql"
  )

  set_gql(
    :add_edits,
    ApiWeb.Schema,
    Wormwood.GQLLoader.load_file!("test/support/mutations/AddEdits.gql")
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "CreateDemo" do
    test "it creates a demo for a storyline with no existing edits", %{
      context: %{current_user: %{email: user_email}} = context,
      public_storyline: %{id: storyline_id} = storyline
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "demo_created",
                           %{demo: _demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      demo_name = "My Demo"

      assert {:ok, query_data} =
               query_gql_by(
                 :create_demo,
                 variables: %{
                   "storylineId" => storyline.id,
                   "name" => demo_name
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "createDemo"])

      assert result["id"] != nil
      assert result["name"] == demo_name
    end

    test "it creates a demo for a storyline with existing edits", %{
      context: %{current_user: %{email: user_email}} = context,
      public_storyline: %{id: storyline_id} = storyline
    } do
      screen = storyline |> Api.StorylinesFixtures.screen_fixture()

      result = query_gql_by(:add_edits, variables: %{"screenId" => screen.id}, context: context)

      assert {:ok, query_data} = result
      no_errors!(query_data)

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "demo_created",
                           %{demo: _demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      demo_name = "My Demo"

      assert {:ok, query_data} =
               query_gql_by(
                 :create_demo,
                 variables: %{
                   "storylineId" => storyline.id,
                   "name" => demo_name
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "createDemo"])

      assert result["id"] != nil
      assert result["name"] == demo_name
    end

    test "it creates a demo for a storyline with empty variables list", %{
      context: %{current_user: %{email: user_email}} = context,
      public_storyline: %{id: storyline_id} = storyline
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "demo_created",
                           %{demo: _demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      demo_name = "My Demo"

      assert {:ok, query_data} =
               query_gql_by(
                 :create_demo,
                 variables: %{
                   "storylineId" => storyline.id,
                   "name" => demo_name,
                   "variables" => []
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "createDemo"])

      assert result["id"] != nil
      assert result["name"] == demo_name
    end

    test "it creates a demo for a storyline with variables", %{
      context: %{current_user: %{email: user_email}} = context,
      public_storyline: %{id: storyline_id} = storyline
    } do
      screen = storyline |> Api.StorylinesFixtures.screen_fixture()

      result = query_gql_by(:add_edits, variables: %{"screenId" => screen.id}, context: context)

      assert {:ok, query_data} = result
      no_errors!(query_data)

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "demo_created",
                           %{demo: _demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      demo_name = "My Demo"

      assert {:ok, query_data} =
               query_gql_by(
                 :create_demo,
                 variables: %{
                   "storylineId" => storyline.id,
                   "name" => demo_name,
                   "variables" => [
                     %{"id" => "123", "name" => "name test", "value" => "Marina"}
                   ]
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "createDemo"])

      assert result["id"] != nil
      assert result["name"] == demo_name
    end

    test "it doesn't update the last edited when creating a demo of a storyline with edits", %{
      context: context,
      public_storyline: storyline
    } do
      screen = storyline |> Api.StorylinesFixtures.screen_fixture()
      query_gql_by(:add_edits, variables: %{"screenId" => screen.id}, context: context)
      storyline = Repo.reload!(storyline)

      demo_name = "My Demo"

      assert {:ok, query_data} =
               query_gql_by(
                 :create_demo,
                 variables: %{
                   "storylineId" => storyline.id,
                   "name" => demo_name
                 },
                 context: context
               )

      no_errors!(query_data)
      storyline_refreshed = Repo.reload!(storyline)
      assert storyline.last_edited == storyline_refreshed.last_edited
    end

    test "it doesn't create a demo if name is empty", %{
      context: context,
      public_storyline: storyline
    } do
      demo_name = ""

      assert {:ok, query_data} =
               query_gql_by(
                 :create_demo,
                 variables: %{
                   "storylineId" => storyline.id,
                   "name" => demo_name
                 },
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Name can't be blank"
    end

    test "authorization", %{context: context, public_storyline: storyline} do
      demo_name = "My Demo"

      TestAccess.assert_roles(
        &query_gql_by(
          :create_demo,
          variables: %{
            "storylineId" => storyline.id,
            "name" => demo_name
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
