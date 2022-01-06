defmodule ApiWeb.GraphQL.CopyScreenTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :copy_screen,
    ApiWeb.Schema,
    "test/support/mutations/CopyScreen.gql"
  )

  load_gql(
    :get_screen,
    ApiWeb.Schema,
    "test/support/queries/GetSmartObjectInstancesFromScreen.gql"
  )

  load_gql(
    :add_smart_object_class,
    ApiWeb.Schema,
    "test/support/mutations/AddSmartObjectClass.gql"
  )

  load_gql(
    :update_smart_object_instances_in_screen,
    ApiWeb.Schema,
    "test/support/mutations/UpdateSmartObjectInstancesInScreen.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "copyScreen" do
    test "it should copy the screen correctly", %{
      screen: screen,
      context: context
    } do
      assert {:ok, query_data} =
               query_gql_by(:copy_screen,
                 variables: %{"screenId" => screen.id, "storylineId" => screen.storyline_id},
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "copyScreen"])

      assert result |> Map.get("id") != screen.id
      assert result |> Map.get("name") == "Copy of #{screen.name}"
    end

    test "it should copy screen smart object instances correctly", %{
      public_storyline: storyline,
      screen: screen,
      context: context
    } do
      class_id =
        query(
          :add_smart_object_class,
          %{
            "storylineId" => storyline.id,
            "smartObjectClass" => smart_object_class_for_gql_fixture()
          },
          context
        )
        |> get_in(["addSmartObjectClass", "id"])

      query(
        :update_smart_object_instances_in_screen,
        %{"screenId" => screen.id, "instances" => [%{"classId" => class_id}]},
        context
      )

      origin_instances =
        query(
          :get_screen,
          %{"storylineId" => storyline.id, "screenId" => screen.id},
          context
        )
        |> get_in(["screen", "smartObjectInstances"])

      copied_screen_id =
        query(
          :copy_screen,
          %{"screenId" => screen.id, "storylineId" => screen.storyline_id},
          context
        )
        |> get_in(["copyScreen", "id"])

      copied_instances =
        query(
          :get_screen,
          %{"storylineId" => storyline.id, "screenId" => copied_screen_id},
          context
        )
        |> get_in(["screen", "smartObjectInstances"])

      # assert instances screen association was successfully remapped during copying
      copied_instances
      |> Enum.each(fn instance -> assert instance["screenId"] == copied_screen_id end)

      # assert normalized copied instances data equality
      for {origin_instance, copied_instance} <- Enum.zip(origin_instances, copied_instances) do
        origin_instance_data = origin_instance |> Map.delete("id") |> Map.delete("screenId")
        origin_instance_data = origin_instance_data["edits"] |> Enum.map(&Map.delete(&1, "id"))

        copied_instance_data = copied_instance |> Map.delete("id") |> Map.delete("screenId")
        copied_instance_data = copied_instance_data["edits"] |> Enum.map(&Map.delete(&1, "id"))

        assert origin_instance_data == copied_instance_data
      end
    end

    test "authorization", %{screen: screen, context: context} do
      TestAccess.assert_roles(
        &query_gql_by(
          :copy_screen,
          variables: %{"screenId" => screen.id, "storylineId" => screen.storyline_id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end

  defp query(query, variables, context) do
    assert {:ok, query_data} = query_gql_by(query, variables: variables, context: context)
    no_errors!(query_data)
    get_in(query_data, [:data])
  end
end
