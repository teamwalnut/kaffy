defmodule ApiWeb.GraphQL.MoveScreens do
  use ApiWeb.GraphQLCase
  import ExUnit.CaptureLog
  alias Api.TestAccess
  load_gql(:move_screens, ApiWeb.Schema, "test/support/mutations/MoveScreens.gql")
  load_gql(:storyline, ApiWeb.Schema, "test/support/queries/Storyline.gql")

  describe "MoveScreen in the same flow" do
    setup [
      :register_and_log_in_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow
    ]

    test "it moves the screen to the new position returns the screen", %{
      default_flow: default_flow,
      public_storyline: storyline,
      context: context
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      query_gql_by(
        :move_screens,
        variables: %{
          "screenIds" => [screen_to_move.id],
          "targetFlowId" => default_flow.id,
          "newPosition" => 3
        },
        context: context
      )
      |> match_snapshot(variation: "mutation", scrub: ["id"])

      query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
      |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
    end

    test "it supports moving the screen to the last position with -1", %{
      default_flow: default_flow,
      public_storyline: storyline,
      context: context
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      query_gql_by(
        :move_screens,
        variables: %{
          "screenIds" => [screen_to_move.id],
          "targetFlowId" => default_flow.id,
          "newPosition" => -1
        },
        context: context
      )
      |> match_snapshot(variation: "mutation", scrub: ["id"])

      query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
      |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
    end

    test "keeps the screen in the same position if its the same as his current position", %{
      default_flow: default_flow,
      public_storyline: storyline,
      context: context
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      query_gql_by(
        :move_screens,
        variables: %{
          "screenIds" => [screen_to_move.id],
          "targetFlowId" => default_flow.id,
          "newPosition" => 2
        },
        context: context
      )
      |> match_snapshot(variation: "mutation", scrub: ["id"])

      query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
      |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
    end

    test "it returns error if changeset errors were raised", %{
      default_flow: default_flow,
      context: context
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      assert capture_log(fn ->
               query_gql_by(
                 :move_screens,
                 variables: %{
                   "screenIds" => [screen_to_move.id],
                   "targetFlowId" => default_flow.id,
                   "newPosition" => -2
                 },
                 context: context
               )
               |> match_snapshot(variation: "error", scrub: ["id"])
             end) == ""
    end

    test "it errors if there is an invalid position passed", %{
      default_flow: default_flow,
      public_storyline: storyline,
      context: context
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      query_gql_by(
        :move_screens,
        variables: %{
          "screenIds" => [screen_to_move.id],
          "targetFlowId" => default_flow.id,
          "newPosition" => -2
        },
        context: context
      )
      |> match_snapshot(variation: "mutation", scrub: ["id"])

      query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
      |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
    end

    test "authorization", %{
      default_flow: default_flow,
      context: context
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      TestAccess.assert_roles(
        &query_gql_by(
          :move_screens,
          variables: %{
            "screenIds" => [screen_to_move.id],
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
           default_flow: default_flow,
           flow: flow,
           public_storyline: storyline,
           context: context
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      query_gql_by(
        :move_screens,
        variables: %{
          "screenIds" => [screen_to_move.id],
          "targetFlowId" => flow.id,
          "newPosition" => 1
        },
        context: context
      )
      |> match_snapshot(variation: "mutation", scrub: ["id"])

      query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
      |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
    end

    test "it supports moving the screen to the last position in a different flow",
         %{
           default_flow: default_flow,
           flow: flow,
           public_storyline: storyline,
           context: context
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      screens = default_flow.screens
      screen_to_move = screens |> Enum.find(fn screen -> screen.flow_screen.position == 2 end)

      query_gql_by(
        :move_screens,
        variables: %{
          "screenIds" => [screen_to_move.id],
          "targetFlowId" => flow.id,
          "newPosition" => -1
        },
        context: context
      )
      |> match_snapshot(variation: "mutation", scrub: ["id"])

      query_gql_by(:storyline, variables: %{"id" => storyline.id}, context: context)
      |> match_snapshot(variation: "storyline", scrub: ["id", "lastEdited"])
    end
  end
end
