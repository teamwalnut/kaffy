defmodule ApiWeb.GraphQL.MoveScreen do
  use ApiWeb.GraphQLCase
  import ExUnit.CaptureLog
  alias Api.TestAccess

  load_gql(
    :move_screen,
    ApiWeb.Schema,
    "test/support/mutations/MoveScreen.gql"
  )

  describe "MoveScreen in the same flow" do
    setup [
      :register_and_log_in_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow
    ]

    test "it moves the screen to the new position returns the screen", %{
      context: context,
      default_flow: default_flow
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      assert {:ok, query_data} =
               query_gql_by(
                 :move_screen,
                 variables: %{
                   "screenId" => screen_to_move.id,
                   "targetFlowId" => default_flow.id,
                   "newPosition" => 3
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "moveScreen"])

      moved_screen =
        Api.Storylines.get_screen!(screen_to_move.id) |> Api.Repo.preload(:flow_screen)

      assert moved_screen.flow_screen.position == 3

      assert result ==
               %{
                 "id" => screen_to_move.id
               }
    end

    test "it supports moving the screen to the last position with -1", %{
      context: context,
      default_flow: default_flow
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      assert {:ok, query_data} =
               query_gql_by(
                 :move_screen,
                 variables: %{
                   "screenId" => screen_to_move.id,
                   "targetFlowId" => default_flow.id,
                   "newPosition" => -1
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "moveScreen"])

      moved_screen =
        Api.Storylines.get_screen!(screen_to_move.id) |> Api.Repo.preload(:flow_screen)

      assert moved_screen.flow_screen.position == screens |> Enum.count()

      assert result ==
               %{
                 "id" => screen_to_move.id
               }
    end

    test "keeps the screen in the same position if its the same as his current position", %{
      context: context,
      default_flow: default_flow
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      assert {:ok, query_data} =
               query_gql_by(
                 :move_screen,
                 variables: %{
                   "screenId" => screen_to_move.id,
                   "targetFlowId" => default_flow.id,
                   "newPosition" => 2
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "moveScreen"])

      moved_screen =
        Api.Storylines.get_screen!(screen_to_move.id) |> Api.Repo.preload(:flow_screen)

      assert moved_screen.flow_screen.position == 2

      assert result ==
               %{
                 "id" => screen_to_move.id
               }
    end

    test "it returns error if changeset errors were raised", %{
      context: context,
      default_flow: default_flow
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      capture_log(fn ->
        assert {:ok, query_data} =
                 query_gql_by(
                   :move_screen,
                   variables: %{
                     "screenId" => screen_to_move.id,
                     "targetFlowId" => default_flow.id,
                     "newPosition" => -2
                   },
                   context: context
                 )

        errors = get_in(query_data, [:errors])
        assert errors != nil

        error = List.first(errors)
        assert error[:message] == "Something went wrong"
      end)
    end

    test "it logs a warning if changeset errors were raised", %{
      context: context,
      default_flow: default_flow
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      assert {:ok, query_data} =
               query_gql_by(
                 :move_screen,
                 variables: %{
                   "screenId" => screen_to_move.id,
                   "targetFlowId" => default_flow.id,
                   "newPosition" => -2
                 },
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Something went wrong"
    end

    test "authorization", %{
      context: context,
      default_flow: default_flow
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      TestAccess.assert_roles(
        &query_gql_by(
          :move_screen,
          variables: %{
            "screenId" => screen_to_move.id,
            "targetFlowId" => default_flow.id,
            "newPosition" => 3
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end

  describe "MoveScreen to a different flow" do
    setup [
      :register_and_log_in_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow,
      :setup_flow
    ]

    test "it moves the screen to the new position in the target flow and remove it from the original flow",
         %{
           context: context,
           default_flow: default_flow,
           flow: flow
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      assert {:ok, query_data} =
               query_gql_by(
                 :move_screen,
                 variables: %{
                   "screenId" => screen_to_move.id,
                   "targetFlowId" => flow.id,
                   "newPosition" => 1
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "moveScreen"])

      moved_screen =
        Api.Storylines.get_screen!(screen_to_move.id) |> Api.Repo.preload(:flow_screen)

      assert moved_screen.flow_screen.position == 1
      assert moved_screen.flow_screen.flow_id == flow.id

      assert result ==
               %{
                 "id" => screen_to_move.id
               }
    end

    test "it supports moving the screen to the last position in a different flow",
         %{
           context: context,
           default_flow: default_flow,
           flow: flow
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      assert {:ok, query_data} =
               query_gql_by(
                 :move_screen,
                 variables: %{
                   "screenId" => screen_to_move.id,
                   "targetFlowId" => flow.id,
                   "newPosition" => -1
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "moveScreen"])

      moved_screen =
        Api.Storylines.get_screen!(screen_to_move.id) |> Api.Repo.preload(:flow_screen)

      flow = flow |> Api.Repo.preload(:screens)

      assert moved_screen.flow_screen.position == flow.screens |> Enum.count()

      assert moved_screen.flow_screen.flow_id == flow.id

      assert result == %{"id" => screen_to_move.id}
    end
  end
end
