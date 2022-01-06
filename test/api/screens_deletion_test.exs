defmodule Api.ScreenDeletionTest do
  use Api.DataCase, async: true

  alias Api.Annotations
  alias Api.Annotations.Annotation
  alias Api.ScreenDeletion
  alias Api.Storylines
  alias Api.Storylines.SmartObjects
  alias Api.Storylines.{Editing, Screen, ScreenGroupingFixtures}

  describe "delete_screen/1 when storyline has 1 screen" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline
    ]

    test "it deletes the start screen", %{public_storyline: storyline, member: member} do
      screen = screen_fixture(storyline)
      storyline = Api.Repo.get(Storylines.Storyline, storyline.id)
      current_datetime = DateTime.utc_now()

      default_flow =
        ScreenGroupingFixtures.default_flow_fixture(storyline.id)
        |> Api.Repo.preload(:flow_screens)

      assert default_flow.flow_screens |> Enum.count() == 1
      assert {:ok, %{screen: %Screen{}}} = ScreenDeletion.delete_screen(screen, member)

      default_flow =
        ScreenGroupingFixtures.default_flow_fixture(storyline.id)
        |> Api.Repo.preload(:flow_screens)

      assert default_flow.flow_screens |> Enum.count() == 0
      storyline = Api.Repo.get(Storylines.Storyline, storyline.id)
      assert storyline.start_screen_id == nil
      assert DateTime.compare(storyline.last_edited, current_datetime) == :gt
    end
  end

  describe "delete_screens/2 when storyline has 1 screen" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline
    ]

    test "it deletes the start screen", %{public_storyline: storyline, member: member} do
      screen = screen_fixture(storyline)
      storyline = Api.Repo.get(Storylines.Storyline, storyline.id)

      default_flow =
        ScreenGroupingFixtures.default_flow_fixture(storyline.id)
        |> Api.Repo.preload(:flow_screens)

      assert default_flow.flow_screens |> Enum.count() == 1
      assert {:ok, [%Screen{}]} = ScreenDeletion.delete_screens(storyline, [screen.id], member)

      default_flow =
        ScreenGroupingFixtures.default_flow_fixture(storyline.id)
        |> Api.Repo.preload(:flow_screens)

      assert default_flow.flow_screens |> Enum.count() == 0
      storyline = Api.Repo.get(Storylines.Storyline, storyline.id)
      assert storyline.start_screen_id == nil
    end

    test "it deletes screen and updates storyline last updated", %{
      public_storyline: storyline,
      member: member
    } do
      screen = screen_fixture(storyline)
      storyline = Api.Repo.get(Storylines.Storyline, storyline.id)

      datetime_before_deleting = DateTime.utc_now()
      assert {:ok, [%Screen{}]} = ScreenDeletion.delete_screens(storyline, [screen.id], member)

      storyline = Api.Repo.get(Storylines.Storyline, storyline.id)
      assert DateTime.compare(storyline.last_edited, datetime_before_deleting) == :gt
    end
  end

  describe "delete_screen/1 when storyline has multiple screens" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow
    ]

    test "it deletes a start screen and sets another screen as a start screen", %{
      public_storyline: storyline,
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      assert {:ok, %{screen: %Screen{}}} = ScreenDeletion.delete_screen(screen1, member)

      storyline = Api.Repo.get(Storylines.Storyline, storyline.id)
      assert storyline.start_screen_id == screen2.id
    end

    test "it also deletes edits using that screen", %{default_flow: default_flow, member: member} do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, _edit} =
        Editing.add_edit(screen1.id, %{
          kind: :link,
          dom_selector: nil,
          css_selector: "some_selector",
          last_edited_at: DateTime.utc_now(),
          link_edit_props: %{
            destination: %{kind: "screen", id: screen2.id}
          }
        })

      {:ok, edit} =
        Editing.add_edit(screen1.id, %{
          kind: :html,
          dom_selector: nil,
          css_selector: "some_selector2",
          last_edited_at: DateTime.utc_now(),
          html_edit_props: %{
            original_value: "<huh/>",
            value: "<new/>"
          }
        })

      assert {:ok, %{screen: %Screen{}}} = ScreenDeletion.delete_screen(screen2, member)
      assert Editing.list_edits(screen1.id) == [edit]
    end

    test "it repositions the other screens in the flow according to what screen was deleted", %{
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_initial_screen1, _initial_screen2, initial_screen3, initial_screen4, initial_screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      assert {:ok, %{screen: %Screen{}}} = ScreenDeletion.delete_screen(initial_screen3, member)

      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)
      [_screen1, _screen2, screen3, screen4] = default_flow.flow_screens |> Enum.map(& &1.screen)

      assert screen3.id == initial_screen4.id
      assert screen4.id == initial_screen5.id
    end
  end

  describe "delete_screens/2 when storyline has multiple screens" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :get_default_flow
    ]

    test "it deletes a start screen and sets another screen as a start screen", %{
      public_storyline: storyline,
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      assert {:ok, [%Screen{}]} = ScreenDeletion.delete_screens(storyline, [screen1.id], member)

      storyline = Api.Repo.get(Storylines.Storyline, storyline.id)
      assert storyline.start_screen_id == screen2.id
    end

    test "it also deletes edits using that screen", %{
      public_storyline: storyline,
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, _screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      {:ok, _edit} =
        Editing.add_edit(screen1.id, %{
          kind: :link,
          dom_selector: nil,
          css_selector: "some_selector",
          last_edited_at: DateTime.utc_now(),
          link_edit_props: %{
            destination: %{kind: "screen", id: screen2.id}
          }
        })

      {:ok, edit} =
        Editing.add_edit(screen1.id, %{
          kind: :html,
          dom_selector: nil,
          css_selector: "some_selector2",
          last_edited_at: DateTime.utc_now(),
          html_edit_props: %{
            original_value: "<huh/>",
            value: "<new/>"
          }
        })

      assert {:ok, [%Screen{}]} = ScreenDeletion.delete_screens(storyline, [screen2.id], member)
      assert Editing.list_edits(screen1.id) == [edit]
    end

    test "it repositions the other screens in the flow according to what screen was deleted", %{
      public_storyline: storyline,
      default_flow: default_flow,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [_initial_screen1, _initial_screen2, initial_screen3, initial_screen4, initial_screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      assert {:ok, [%Screen{}]} =
               ScreenDeletion.delete_screens(storyline, [initial_screen3.id], member)

      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)
      [_screen1, _screen2, screen3, screen4] = default_flow.flow_screens |> Enum.map(& &1.screen)

      assert screen3.id == initial_screen4.id
      assert screen4.id == initial_screen5.id
    end
  end

  describe "delete_screen/1 when there are related annotations" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :setup_guide,
      :get_default_flow
    ]

    @valid_point_attrs %{
      kind: :point,
      message: "some message",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z",
      frame_selectors: ["iframe"],
      css_selector: "some css selector",
      anchor: :top
    }

    test "delete annotations per screen and reposition other annotations",
         %{default_flow: default_flow, guide: guide, member: member} do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      point_attrs_1 = Enum.into(%{screen_id: screen1.id}, @valid_point_attrs)
      point_attrs_2 = Enum.into(%{screen_id: screen2.id}, @valid_point_attrs)
      point_attrs_3 = Enum.into(%{screen_id: screen3.id}, @valid_point_attrs)

      assert {:ok, %Annotation{} = annotation0} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs_1, :point, member)

      assert {:ok, %Annotation{} = annotation1} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs_2, :point, member)

      assert {:ok, %Annotation{} = annotation2} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs_1, :point, member)

      assert {:ok, %Annotation{} = annotation3} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs_3, :point, member)

      assert annotation0.step == 0
      assert annotation1.step == 1
      assert annotation2.step == 2
      assert annotation3.step == 3

      assert {:ok, %{screen: %Screen{}}} = ScreenDeletion.delete_screen(screen1, member)

      annotations = Annotation.all_guide_annotations_query(guide.id) |> Repo.all()

      refute annotation0 in annotations
      refute annotation2 in annotations
      assert annotations |> Enum.at(0) |> Map.get(:step) == 0
      assert annotations |> Enum.at(1) |> Map.get(:step) == 1
    end
  end

  describe "delete_screens/2 when there are related annotations" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :setup_guide,
      :get_default_flow
    ]

    @valid_point_attrs %{
      kind: :point,
      message: "some message",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z",
      frame_selectors: ["iframe"],
      css_selector: "some css selector",
      anchor: :top
    }

    test "delete annotations per screen and reposition other annotations",
         %{guide: guide, default_flow: default_flow, public_storyline: storyline, member: member} do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)

      [screen1, screen2, screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      point_attrs_1 = Enum.into(%{screen_id: screen1.id}, @valid_point_attrs)
      point_attrs_2 = Enum.into(%{screen_id: screen2.id}, @valid_point_attrs)
      point_attrs_3 = Enum.into(%{screen_id: screen3.id}, @valid_point_attrs)

      assert {:ok, %Annotation{} = annotation0} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs_1, :point, member)

      assert {:ok, %Annotation{} = annotation1} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs_2, :point, member)

      assert {:ok, %Annotation{} = annotation2} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs_1, :point, member)

      assert {:ok, %Annotation{} = annotation3} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs_3, :point, member)

      assert annotation0.step == 0
      assert annotation1.step == 1
      assert annotation2.step == 2
      assert annotation3.step == 3

      assert {:ok, [%Screen{}]} = ScreenDeletion.delete_screens(storyline, [screen1.id], member)

      annotations = Annotation.all_guide_annotations_query(guide.id) |> Repo.all()

      refute annotation0 in annotations
      refute annotation2 in annotations
      assert annotations |> Enum.at(0) |> Map.get(:step) == 0
      assert annotations |> Enum.at(1) |> Map.get(:step) == 1
    end
  end

  describe "delete_screen/1 when there are related smart object classes" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :setup_guide,
      :get_default_flow
    ]

    test "delete related smart objects classes and instances link edits",
         %{
           default_flow: default_flow,
           member: member,
           public_storyline: storyline
         } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, screen3, _screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      class = %SmartObjects.Class{
        storyline_id: storyline.id,
        name: "test smart object",
        thumbnail: "===",
        css_selector: "div > div",
        dom_selector: nil,
        edits: [
          smart_object_class_link_edit_fixture(screen2.id),
          smart_object_class_link_edit_fixture(screen3.id)
        ]
      }

      {:ok, class} = SmartObjects.create_class(class, member)

      {:ok, _instance} =
        SmartObjects.update_instances_in_screen(
          screen1.id,
          [%{class_id: class.id}],
          member
        )

      screen1 = screen1 |> Api.Repo.reload()
      screen1_instance = screen1.smart_object_instances |> Enum.at(0)

      assert length(screen1_instance.edits) == 2
      assert length(class.edits) == 2

      assert {:ok, %{screen: %Screen{}}} = ScreenDeletion.delete_screen(screen2, member)

      class = SmartObjects.get_class!(class.id)
      {:ok, instances} = SmartObjects.list_instances(screen1.id)
      instance = instances |> Enum.at(0)

      assert length(class.edits) == 1
      assert length(instance.edits) == 1

      screen3_id = screen3.id

      assert [
               %{
                 "link_edit_props" => %{
                   "destination" => %{
                     "delay_ms" => _,
                     "id" => ^screen3_id,
                     "kind" => "screen"
                   }
                 }
               }
             ] = class.edits

      assert [
               %{
                 "link_edit_props" => %{
                   "destination" => %{
                     "delay_ms" => _,
                     "id" => ^screen3_id,
                     "kind" => "screen"
                   }
                 }
               }
             ] = instance.edits
    end
  end

  describe "delete_screens/2 when there are related smart object classes" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :setup_guide,
      :get_default_flow
    ]

    test "delete related smart objects classes and instances link edits",
         %{
           default_flow: default_flow,
           member: member,
           public_storyline: storyline
         } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)

      [screen1, screen2, screen3, screen4, _screen5] =
        default_flow.flow_screens |> Enum.map(& &1.screen)

      class = %SmartObjects.Class{
        storyline_id: storyline.id,
        name: "test smart object",
        thumbnail: "===",
        css_selector: "div > div",
        edits: [
          smart_object_class_link_edit_fixture(screen2.id),
          smart_object_class_link_edit_fixture(screen3.id),
          smart_object_class_link_edit_fixture(screen4.id)
        ]
      }

      {:ok, class} = SmartObjects.create_class(class, member)

      {:ok, _instance} =
        SmartObjects.update_instances_in_screen(
          screen1.id,
          [%{class_id: class.id}],
          member
        )

      screen1 = screen1 |> Api.Repo.reload()
      screen1_instance = screen1.smart_object_instances |> Enum.at(0)

      assert length(screen1_instance.edits) == 3
      assert length(class.edits) == 3

      assert {:ok, [%Screen{}, %Screen{}]} =
               ScreenDeletion.delete_screens(storyline, [screen2.id, screen3.id], member)

      class = SmartObjects.get_class!(class.id)
      {:ok, instances} = SmartObjects.list_instances(screen1.id)
      instance = instances |> Enum.at(0)

      assert length(instance.edits) == 1
      assert length(class.edits) == 1

      screen4_id = screen4.id

      assert [
               %{
                 "link_edit_props" => %{
                   "destination" => %{
                     "delay_ms" => _,
                     "id" => ^screen4_id,
                     "kind" => "screen"
                   }
                 }
               }
             ] = class.edits

      assert [
               %{
                 "link_edit_props" => %{
                   "destination" => %{
                     "delay_ms" => _,
                     "id" => ^screen4_id,
                     "kind" => "screen"
                   }
                 }
               }
             ] = instance.edits
    end
  end

  defp get_flow_with_preloaded_ordered_screens(flow_id) do
    alias Api.Storylines.ScreenGrouping.{Flow, FlowScreen}

    Repo.get!(Flow, flow_id)
    |> Repo.preload(flow_screens: FlowScreen.order_by_position_query())
    |> Repo.preload(flow_screens: [:screen])
  end
end
