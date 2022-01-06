defmodule ApiWeb.GraphQL.CopyScreensTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines
  alias Api.TestAccess

  load_gql(:copy_screens, ApiWeb.Schema, "test/support/mutations/CopyScreens.gql")
  load_gql(:storyline, ApiWeb.Schema, "test/support/queries/Storyline.gql")

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

  load_gql(
    :get_screen_instances,
    ApiWeb.Schema,
    "test/support/queries/GetSmartObjectInstancesFromScreen.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline
  ]

  test "it should copy one screen correctly", %{public_storyline: storyline, context: context} do
    screen = screen_fixture(storyline)

    query_gql_by(:copy_screens,
      variables: %{"screenIds" => [screen.id], "storylineId" => screen.storyline_id},
      context: context
    )
    |> match_snapshot(variation: "mutation", scrub: ["id", "lastEdited"])

    query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
    |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
  end

  test "it should update storyline last updated when coping screens", %{
    public_storyline: storyline,
    context: context
  } do
    screen = screen_fixture(storyline)

    time_before_copying = DateTime.utc_now()

    result =
      query_gql_by(:copy_screens,
        variables: %{"screenIds" => [screen.id], "storylineId" => screen.storyline_id},
        context: context
      )

    assert {:ok, query_data} = result
    no_errors!(query_data)

    storyline = Storylines.get_storyline!(storyline.id)
    assert DateTime.compare(storyline.last_edited, time_before_copying) == :gt
  end

  test "authorization", %{public_storyline: storyline, context: context} do
    screen = screen_fixture(storyline)

    TestAccess.assert_roles(
      &query_gql_by(
        :copy_screens,
        variables: %{"screenIds" => [screen.id], "storylineId" => screen.storyline_id},
        context: Map.put(context, :current_member, &1)
      ),
      context.current_member,
      %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
    )
  end

  test "it should copy multiple screens correctly", %{
    public_storyline: storyline,
    context: context
  } do
    screen_1 = screen_fixture(storyline, name: "screen2")
    screen_2 = screen_fixture(storyline, name: "screen3")

    query_gql_by(:copy_screens,
      variables: %{
        "screenIds" => [screen_1.id, screen_2.id],
        "storylineId" => storyline.id
      },
      context: context
    )
    |> match_snapshot(variation: "mutation", scrub: ["id", "lastEdited"])

    query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
    |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
  end

  test "it should copy multiple screens in multiple flows correctly", %{
    public_storyline: storyline,
    context: context
  } do
    screen_fixture(storyline, %{name: "screen before copied screen"})
    screen = screen_fixture(storyline, %{name: "screen to be copied"})
    screen_fixture(storyline, %{name: "screen after copied screen"})
    flow = flow_fixture(storyline.id)

    screen_in_flow_fixture(storyline, flow, %{
      name: "screen before copied screen in flow"
    })

    screen_in_flow =
      screen_in_flow_fixture(storyline, flow, %{
        name: "screen to be copied in flow"
      })

    screen_in_flow_fixture(storyline, flow, %{
      name: "screen after copied screen in flow"
    })

    query_gql_by(:copy_screens,
      variables: %{
        "screenIds" => [screen.id, screen_in_flow.id],
        "storylineId" => storyline.id
      },
      context: context
    )
    |> match_snapshot(variation: "mutation", scrub: ["id", "lastEdited"])

    query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
    |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
  end

  test "it should copy multiple screens with smart object instances correctly", %{
    public_storyline: storyline,
    context: context
  } do
    screen_1 = screen_fixture(storyline, name: "screen1")
    screen_2 = screen_fixture(storyline, name: "screen2")

    class_for_gql = smart_object_class_for_gql_fixture()

    class_id =
      query(
        :add_smart_object_class,
        %{
          "storylineId" => storyline.id,
          "smartObjectClass" => class_for_gql
        },
        context
      )
      |> get_in(["addSmartObjectClass", "id"])

    query(
      :update_smart_object_instances_in_screen,
      %{"screenId" => screen_1.id, "instances" => [%{"classId" => class_id}]},
      context
    )

    query(
      :update_smart_object_instances_in_screen,
      %{"screenId" => screen_2.id, "instances" => [%{"classId" => class_id}]},
      context
    )

    [
      %{"id" => copied_screen_1_id, "name" => "Copy of screen1"},
      %{"id" => copied_screen_2_id, "name" => "Copy of screen2"}
    ] =
      query(
        :copy_screens,
        %{
          "screenIds" => [screen_1.id, screen_2.id],
          "storylineId" => storyline.id
        },
        context
      )
      |> get_in(["copyScreens"])

    copied_screen_1_instances =
      query(
        :get_screen_instances,
        %{"storylineId" => storyline.id, "screenId" => copied_screen_1_id},
        context
      )
      |> get_in(["screen", "smartObjectInstances"])

    copied_screen_2_instances =
      query(
        :get_screen_instances,
        %{"storylineId" => storyline.id, "screenId" => copied_screen_2_id},
        context
      )
      |> get_in(["screen", "smartObjectInstances"])

    # assert instances screen association was successfully remapped during copying
    copied_screen_1_instances
    |> Enum.each(fn instance ->
      assert instance["screenId"] == copied_screen_1_id
    end)

    # assert instances screen two association was successfully remapped during copying
    copied_screen_2_instances
    |> Enum.each(fn instance ->
      assert instance["screenId"] == copied_screen_2_id
    end)

    # assert normalized copied instances data equality
    for {screen_1_instance, screen_2_instance} <-
          Enum.zip(copied_screen_1_instances, copied_screen_2_instances) do
      screen_1_instance_data = screen_1_instance |> Map.delete("id") |> Map.delete("screenId")
      screen_1_instance_data = screen_1_instance_data["edits"] |> Enum.map(&Map.delete(&1, "id"))

      screen_2_instance_data = screen_2_instance |> Map.delete("id") |> Map.delete("screenId")
      screen_2_instance_data = screen_2_instance_data["edits"] |> Enum.map(&Map.delete(&1, "id"))

      assert screen_1_instance_data == screen_2_instance_data
    end
  end

  defp query(query, variables, context) do
    assert {:ok, query_data} = query_gql_by(query, variables: variables, context: context)
    no_errors!(query_data)
    get_in(query_data, [:data])
  end
end
