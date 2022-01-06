defmodule ApiWeb.GraphQL.UpdateDemoVersion do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :update_demo_version,
    ApiWeb.Schema,
    "test/support/mutations/demos/UpdateDemoVersion.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "UpdateDemoVersion" do
    test "it updates a demo version for a demo", %{
      context: %{current_user: %{email: user_email}} = context,
      member: member,
      public_storyline: %{id: storyline_id} = storyline
    } do
      %{demo: demo} = storyline |> demo_fixture(member)

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "demo_updated",
                           %{demo: _demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_demo_version,
                 variables: %{
                   "storylineId" => storyline.id,
                   "demoId" => demo.id
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "updateDemoVersion"])
      assert result["id"] != nil
      assert result["name"] == demo.name
      assert result["storyline"]["id"] == storyline.id
    end

    test "it updates a demo version for a demo with variables list", %{
      context: %{current_user: %{email: user_email}} = context,
      member: member,
      public_storyline: %{id: storyline_id} = storyline
    } do
      %{demo: demo} = storyline |> demo_fixture(member)

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "demo_updated",
                           %{demo: _demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_demo_version,
                 variables: %{
                   "storylineId" => storyline.id,
                   "demoId" => demo.id,
                   "variables" => [
                     %{"id" => "123", "name" => "name test", "value" => "Marina"}
                   ]
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "updateDemoVersion"])
      assert result["id"] != nil
      assert result["name"] == demo.name
      assert result["storyline"]["id"] == storyline.id
    end

    test "authorization", %{context: context, member: member, public_storyline: storyline} do
      %{demo: demo} = storyline |> demo_fixture(member)

      TestAccess.assert_roles(
        &query_gql_by(
          :update_demo_version,
          variables: %{
            "storylineId" => storyline.id,
            "demoId" => demo.id
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
