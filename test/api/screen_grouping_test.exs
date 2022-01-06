defmodule Api.ScreenGroupingTest do
  use Api.DataCase, async: true

  alias Api.Storylines
  alias Api.Storylines.ScreenGrouping
  alias Api.Storylines.ScreenGrouping.{Flow, FlowScreen}

  describe "flows" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :get_default_flow
    ]

    @valid_attrs %{name: "My Flow"}
    @invalid_attrs %{name: nil}

    test "list_flows/1 returns all the flows of a storyline", %{
      public_storyline: public_storyline,
      default_flow: default_flow
    } do
      returned_flows = Storylines.list_flows(public_storyline.id)
      returned_flows_ids = returned_flows |> Enum.map(fn flow -> flow.id end)
      assert returned_flows_ids == [default_flow.id]
    end

    test "create_flow/2 creates a regular flow for the passed storyline when passed valid attrs",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      assert {:ok, flow} = Storylines.create_flow(public_storyline.id, @valid_attrs, member)
      assert flow.name == @valid_attrs[:name]
      assert flow.is_default == false
      assert flow.position != 1
      assert flow.storyline_id == public_storyline.id
    end

    test "create_flow/2 doesn't creates a regular flow for the passed storyline when passed invalid attrs",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      assert {:error, %Ecto.Changeset{}} =
               Storylines.create_flow(public_storyline.id, @invalid_attrs, member)
    end

    test "rename_flow/2 updates the flow's name when called with valid attrs", %{
      public_storyline: public_storyline,
      member: member
    } do
      flow = public_storyline.id |> flow_fixture()
      assert {:ok, renamed_flow} = Storylines.rename_flow(flow.id, @valid_attrs[:name], member)
      assert renamed_flow.name == @valid_attrs[:name]
    end

    test "rename_flow/2 doesn't update the flow's name when called with invalid attrs", %{
      public_storyline: public_storyline,
      member: member
    } do
      flow = public_storyline.id |> flow_fixture()
      assert {:error, %Ecto.Changeset{}} = Storylines.rename_flow(flow.id, @invalid_attrs, member)
    end
  end

  describe "delete_flow/1" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen,
      :get_default_flow,
      :setup_flow
    ]

    test "errors if pass with a default flow", %{
      default_flow: default_flow,
      member: member
    } do
      assert {:error, _} = Storylines.delete_flow(default_flow.id, member)
    end

    test "deletes a non default flow", %{
      flow: flow,
      member: member
    } do
      before_flows = Storylines.list_flows(flow.storyline_id)
      assert {:ok, _} = Storylines.delete_flow(flow.id, member)
      after_flows = Storylines.list_flows(flow.storyline_id)
      assert Enum.count(before_flows) - Enum.count(after_flows) == 1
    end

    test "moves the deleted flow's screens to the default flow", %{
      screen: screen,
      default_flow: default_flow,
      flow: flow,
      member: member
    } do
      Storylines.delete_flow(flow.id, member)
      default_flow = default_flow |> Api.Repo.preload(:flow_screens)

      default_flow_screens_ids = get_flow_screens_ids(default_flow)
      assert Enum.member?(default_flow_screens_ids, screen.id) == true
    end

    test "it repositions the other flow in the storyline according to what flow was deleted", %{
      public_storyline: storyline,
      flow: flow1,
      member: member
    } do
      flow2 = flow_fixture(storyline.id)
      assert flow2.position == 3

      Storylines.delete_flow(flow1.id, member)

      assert [_reloaded_default_flow, reloaded_flow2] = Storylines.list_flows(storyline.id)
      assert reloaded_flow2.position == 2
    end
  end

  describe "reposition_flow/2" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen,
      :get_default_flow,
      :setup_multiple_flows
    ]

    test "updates the repositioned flow", %{
      flows: flows,
      member: member
    } do
      second_position_flow = Enum.at(flows, 0)
      {:ok, repositioned_flows} = Storylines.reposition_flow(second_position_flow.id, 4, member)

      repositioned_flows = repositioned_flows |> Map.drop(["deferred"])

      assert repositioned_flows |> Enum.count() === 3
      assert repositioned_flows["4"].id === second_position_flow.id
    end

    test "errors if try to reposition to default flow position", %{
      flows: flows,
      member: member
    } do
      {:error, _, changeset, _} = Storylines.reposition_flow(Enum.at(flows, 1).id, 1, member)

      assert false == Enum.empty?(changeset.errors)
      assert false == changeset.valid?
    end

    test "errors if try to reposition default flow", %{default_flow: default_flow, member: member} do
      {:error, _, changeset, _} = Storylines.reposition_flow(default_flow.id, 3, member)

      assert false == Enum.empty?(changeset.errors)
      assert false == changeset.valid?
    end
  end

  describe "move_screen/3 in the same flow" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow
    ]

    test "moves the screen to the last position in the same flow",
         %{
           default_flow: default_flow,
           member: member
         } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, %{"5" => moved_flow_screen}} =
        Storylines.move_screen(screen2.id, default_flow.id, :last, member)

      assert moved_flow_screen.screen_id == screen2.id
    end

    test "moves the screen to the new position if the new position is higher than its current position",
         %{
           default_flow: default_flow,
           member: member
         } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, screen3, screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, %{"2" => moved_flow_screen, "3" => moved_flow_screen2, "4" => moved_flow_screen3}} =
        Storylines.move_screen(screen2.id, default_flow.id, 4, member)

      assert moved_flow_screen.screen_id == screen3.id
      assert moved_flow_screen.position == 2
      assert moved_flow_screen2.screen_id == screen4.id
      assert moved_flow_screen2.position == 3
      assert moved_flow_screen3.screen_id == screen2.id
      assert moved_flow_screen3.position == 4
    end

    test "moves the screen to the new position if the new position is lower than its current position",
         %{
           default_flow: default_flow,
           member: member
         } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, screen3, screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, %{"2" => moved_flow_screen, "3" => moved_flow_screen2, "4" => moved_flow_screen3}} =
        Storylines.move_screen(screen4.id, default_flow.id, 2, member)

      assert moved_flow_screen.screen_id == screen4.id
      assert moved_flow_screen.position == 2
      assert moved_flow_screen2.screen_id == screen2.id
      assert moved_flow_screen2.position == 3
      assert moved_flow_screen3.screen_id == screen3.id
      assert moved_flow_screen3.position == 4
    end

    test "keeps the screen in the same position if its the same as his current position", %{
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, result} = Storylines.move_screen(screen2.id, default_flow.id, 2, member)
      assert %{"flowscreen" => flow_screen} = result

      assert flow_screen.screen_id == screen2.id
      assert flow_screen.position == 2
    end

    test "errors if passed with invalid arguments", %{
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:error, _errored_operation, %Ecto.Changeset{} = errored_changeset, _changes_so_far} =
        Storylines.move_screen(screen2.id, default_flow.id, -2, member)

      assert Enum.empty?(errored_changeset.errors) == false
      assert errored_changeset.valid? == false
    end
  end

  describe "move_screens/3 in the same flow" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow
    ]

    test "moves the screen to the last position in the same flow",
         %{
           default_flow: default_flow,
           member: member
         } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, [_, _, _, moved_flow_screen]} =
        Storylines.move_screens([screen2.id], default_flow.id, -1, member)

      assert moved_flow_screen.screen_id == screen2.id
    end

    test "moves the screen to the new position if the new position is higher than its current position",
         %{
           default_flow: default_flow,
           member: member
         } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, screen3, screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, [moved_flow_screen, moved_flow_screen2, moved_flow_screen3]} =
        Storylines.move_screens([screen2.id], default_flow.id, 4, member)

      assert moved_flow_screen.screen_id == screen3.id
      assert moved_flow_screen.position == 2
      assert moved_flow_screen2.screen_id == screen4.id
      assert moved_flow_screen2.position == 3
      assert moved_flow_screen3.screen_id == screen2.id
      assert moved_flow_screen3.position == 4
    end

    test "moves the screen to the new position if the new position is lower than its current position",
         %{
           default_flow: default_flow,
           member: member
         } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, screen3, screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, %{"2" => moved_flow_screen, "3" => moved_flow_screen2, "4" => moved_flow_screen3}} =
        Storylines.move_screen(screen4.id, default_flow.id, 2, member)

      assert moved_flow_screen.screen_id == screen4.id
      assert moved_flow_screen.position == 2
      assert moved_flow_screen2.screen_id == screen2.id
      assert moved_flow_screen2.position == 3
      assert moved_flow_screen3.screen_id == screen3.id
      assert moved_flow_screen3.position == 4
    end

    # NOTE(Jaap)
    # This test is flakey. I don't know why it's not consistent
    test "keeps the screen in the same position if its the same as his current position", %{
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, screen3, screen4, screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      assert screen1.flow_screen.position == 1
      assert screen2.flow_screen.position == 2
      assert screen3.flow_screen.position == 3
      assert screen4.flow_screen.position == 4
      assert screen5.flow_screen.position == 5
      {:ok, []} = Storylines.move_screens([screen2.id], default_flow.id, 2, member)
    end

    test "errors if passed with invalid arguments", %{
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:error, :invalid_position} =
        Storylines.move_screens([screen2.id], default_flow.id, -2, member)
    end
  end

  describe "move_screen/3 to a different flow" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow,
      :setup_flow
    ]

    test "moves the screen to the last position in the target flow",
         %{
           default_flow: default_flow,
           flow: target_flow,
           member: member
         } do
      origin_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, _screen2, _screen3, _screen4, _screen5] =
        origin_flow.flow_screens |> Enum.map(& &1.screen)

      Storylines.move_screen(screen1.id, target_flow.id, :last, member)

      updated_origin_flow = get_flow_with_preloaded_ordered_screens(origin_flow.id)
      updated_flow = get_flow_with_preloaded_ordered_screens(target_flow.id)

      last_screen =
        updated_flow.flow_screens
        |> Enum.map(& &1.screen)
        |> Enum.at(length(updated_flow.flow_screens) - 1)

      assert last_screen.id == screen1.id
      assert Enum.count(updated_origin_flow.flow_screens) == 4
      assert Enum.count(updated_flow.flow_screens) == 1
    end

    test "moves the screen to the new position in the target flow and remove it from the original flow",
         %{default_flow: default_flow, flow: target_flow, member: member} do
      origin_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, screen3, screen4, screen5] =
        origin_flow.flow_screens |> Enum.map(& &1.screen)

      Storylines.move_screen(screen2.id, target_flow.id, 1, member)

      {:ok,
       %{
         "add_screen_to_target_flow" => target_flow_moved_flow_screen,
         "target_flow2" => target_flow_moved_flow_screen2,
         "origin_flow2" => origin_flow_moved_flow_screen2,
         "origin_flow3" => origin_flow_moved_flow_screen3
       }} = Storylines.move_screen(screen3.id, target_flow.id, 1, member)

      assert target_flow_moved_flow_screen.screen_id == screen3.id
      assert target_flow_moved_flow_screen.position == 1
      assert target_flow_moved_flow_screen.flow_id == target_flow.id
      assert target_flow_moved_flow_screen2.screen_id == screen2.id
      assert target_flow_moved_flow_screen2.position == 2
      assert target_flow_moved_flow_screen2.flow_id == target_flow.id

      assert origin_flow_moved_flow_screen2.screen_id == screen4.id
      assert origin_flow_moved_flow_screen2.position == 2
      assert origin_flow_moved_flow_screen3.screen_id == screen5.id
      assert origin_flow_moved_flow_screen3.position == 3

      updated_origin_flow = get_flow_with_preloaded_ordered_screens(origin_flow.id)
      updated_flow = get_flow_with_preloaded_ordered_screens(target_flow.id)

      assert Enum.count(updated_origin_flow.flow_screens) == 3
      assert Enum.count(updated_flow.flow_screens) == 2
    end

    test "make sure the other flow is compacted",
         %{default_flow: default_flow, flow: target_flow, member: member} do
      origin_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, _screen2, _screen3, _screen4, _screen5] =
        origin_flow.flow_screens |> Enum.map(& &1.screen)

      Storylines.move_screen(screen1.id, target_flow.id, :last, member)

      updated_origin_flow = get_flow_with_preloaded_ordered_screens(origin_flow.id)

      assert [%{position: 1}, %{position: 2}, %{position: 3}, %{position: 4}] =
               updated_origin_flow.flow_screens
    end
  end

  describe "move_screens/3 to a different flow" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow,
      :setup_flow
    ]

    test "moves the screen to the last position in the target flow",
         %{
           default_flow: default_flow,
           flow: target_flow,
           member: member
         } do
      origin_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, _screen2, _screen3, _screen4, _screen5] =
        origin_flow.flow_screens |> Enum.map(& &1.screen)

      Storylines.move_screens([screen1.id], target_flow.id, -1, member)

      updated_origin_flow = get_flow_with_preloaded_ordered_screens(origin_flow.id)
      updated_flow = get_flow_with_preloaded_ordered_screens(target_flow.id)

      last_screen =
        updated_flow.flow_screens
        |> Enum.map(& &1.screen)
        |> Enum.at(length(updated_flow.flow_screens) - 1)

      assert last_screen.id == screen1.id
      assert length(updated_origin_flow.flow_screens) == 4
      assert length(updated_flow.flow_screens) == 1
    end

    test "moves the screen to the new position in the target flow and remove it from the original flow",
         %{default_flow: default_flow, flow: target_flow, member: member} do
      origin_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_screen1, screen2, screen3, _screen4, _screen5] =
        origin_flow.flow_screens |> Enum.map(& &1.screen)

      Storylines.move_screens([screen2.id], target_flow.id, 1, member)

      {:ok,
       [
         target_flow_moved_flow_screen,
         target_flow_moved_flow_screen2
       ]} = Storylines.move_screens([screen3.id], target_flow.id, 1, member)

      assert target_flow_moved_flow_screen.screen_id == screen3.id
      assert target_flow_moved_flow_screen.position == 1
      assert target_flow_moved_flow_screen.flow_id == target_flow.id
      assert target_flow_moved_flow_screen2.screen_id == screen2.id
      assert target_flow_moved_flow_screen2.position == 2
      assert target_flow_moved_flow_screen2.flow_id == target_flow.id

      updated_origin_flow = get_flow_with_preloaded_ordered_screens(origin_flow.id)
      updated_flow = get_flow_with_preloaded_ordered_screens(target_flow.id)

      assert length(updated_origin_flow.flow_screens) == 3
      assert length(updated_flow.flow_screens) == 2
    end

    test "moves multiple screens",
         %{default_flow: default_flow, flow: target_flow, member: member} do
      origin_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, screen3, screen4, _screen5] =
        origin_flow.flow_screens |> Enum.map(& &1.screen)

      Storylines.move_screens([screen2.id, screen3.id], target_flow.id, 1, member)

      {:ok,
       [
         moved_screen1,
         moved_screen2,
         moved_screen3
       ]} = Storylines.move_screens([screen1.id, screen4.id], target_flow.id, 2, member)

      assert moved_screen1.screen_id == screen1.id
      assert moved_screen1.position == 2
      assert moved_screen1.flow_id == target_flow.id
      assert moved_screen2.screen_id == screen4.id
      assert moved_screen2.position == 3
      assert moved_screen2.flow_id == target_flow.id
      assert moved_screen3.screen_id == screen3.id
      assert moved_screen3.position == 4
      assert moved_screen3.flow_id == target_flow.id

      updated_origin_flow = get_flow_with_preloaded_ordered_screens(origin_flow.id)
      updated_flow = get_flow_with_preloaded_ordered_screens(target_flow.id)

      assert length(updated_origin_flow.flow_screens) == 1
      assert length(updated_flow.flow_screens) == 4
    end

    test "make sure the other flow is compacted",
         %{default_flow: default_flow, flow: target_flow, member: member} do
      origin_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, _screen2, _screen3, _screen4, _screen5] =
        origin_flow.flow_screens |> Enum.map(& &1.screen)

      Storylines.move_screens([screen1.id], target_flow.id, -1, member)

      updated_origin_flow = get_flow_with_preloaded_ordered_screens(origin_flow.id)

      assert [%{position: 1}, %{position: 2}, %{position: 3}, %{position: 4}] =
               updated_origin_flow.flow_screens
    end
  end

  describe "position_field_for_entity/1" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow
    ]

    test "when called with entity %Flow{} it returns :position", %{
      default_flow: default_flow
    } do
      assert :position ==
               ScreenGrouping.position_field_for_entity(default_flow)
    end

    test "when called with entity %FlowScreen{} it returns :position", %{
      default_flow: default_flow
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, _screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      assert :position ==
               ScreenGrouping.position_field_for_entity(screen1.flow_screen)
    end

    test "when called with an unsupported entity it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        ScreenGrouping.position_field_for_entity(%Api.Storylines.Storyline{})
      end
    end
  end

  describe "position_field_for_entity_type/1" do
    test "when called with entity_type Flow it returns :position" do
      assert :position ==
               ScreenGrouping.position_field_for_entity_type(Flow)
    end

    test "when called with entity_tyoe FlowScreen it returns :position" do
      assert :position ==
               ScreenGrouping.position_field_for_entity_type(FlowScreen)
    end

    test "when called with an unsupported entity_tyoe it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        ScreenGrouping.position_field_for_entity(Api.Storylines.Storyline)
      end
    end
  end

  describe "get_entities_to_reposition/1" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow,
      :setup_flow
    ]

    test "when called with entity %Flow{}", %{
      default_flow: default_flow,
      flow: other_flow
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      received_flows = ScreenGrouping.get_entities_to_reposition(other_flow)

      assert Enum.map(received_flows, fn flow -> flow.id end) == [default_flow.id, other_flow.id]
    end

    test "when called with entity %FlowScreen{} it returns all the entity's siblings", %{
      default_flow: default_flow
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, screen3, screen4, screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      expected_flow_screens = [
        screen1.flow_screen,
        screen2.flow_screen,
        screen3.flow_screen,
        screen4.flow_screen,
        screen5.flow_screen
      ]

      [flow_screen1 = %{id: id1}, %{id: id2}, %{id: id3}, %{id: id4}, %{id: id5}] =
        expected_flow_screens

      received_flow_screens = ScreenGrouping.get_entities_to_reposition(flow_screen1)

      assert [%{id: ^id1}, %{id: ^id2}, %{id: ^id3}, %{id: ^id4}, %{id: ^id5}] =
               received_flow_screens
    end

    test "when called with an unsupported entity it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        ScreenGrouping.get_entities_to_reposition(%Api.Storylines.Storyline{})
      end
    end
  end

  describe "reposition_changeset_func_for_entity/1" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow
    ]

    test "when called with entity %Flow{}", %{
      default_flow: default_flow
    } do
      expected_func = &Flow.reposition_changeset/2

      assert expected_func ==
               ScreenGrouping.reposition_changeset_func_for_entity(default_flow)
    end

    test "when called with entity %FlowScreen{}", %{
      default_flow: default_flow
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, _screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      expected_func = &FlowScreen.reposition_changeset/2

      assert expected_func ==
               ScreenGrouping.reposition_changeset_func_for_entity(screen1.flow_screen)
    end

    test "when called with an unsupported entity it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        ScreenGrouping.reposition_changeset_func_for_entity(%Api.Storylines.Storyline{})
      end
    end
  end

  describe "reposition_changeset_func_for_entity_type/1" do
    test "when called with entity_type Flow" do
      expected_func = &Flow.reposition_changeset/2

      assert expected_func ==
               ScreenGrouping.reposition_changeset_func_for_entity_type(Flow)
    end

    test "when called with entity_type FlowScreen" do
      expected_func = &FlowScreen.reposition_changeset/2

      assert expected_func ==
               ScreenGrouping.reposition_changeset_func_for_entity_type(FlowScreen)
    end

    test "when called with an unsupported entity it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        ScreenGrouping.reposition_changeset_func_for_entity_type(Api.Storylines.Storyline)
      end
    end
  end

  defp get_flow_with_preloaded_ordered_screens(flow_id) do
    Repo.get!(Flow, flow_id)
    |> Repo.preload(flow_screens: FlowScreen.order_by_position_query())
    |> Repo.preload(flow_screens: [screen: [:flow_screen]])
  end

  defp get_flow_screens_ids(flow) do
    flow.flow_screens |> Enum.map(fn flow_screen -> flow_screen.screen_id end)
  end
end
