defmodule Api.AnnotationsTest do
  use Api.DataCase, async: true

  alias Api.Annotations
  alias Api.Annotations.{Annotation, Guide}
  alias Api.Storylines.ScreenGrouping.{Flow, FlowScreen}

  describe "guides" do
    setup [:setup_user, :setup_company, :setup_member, :setup_public_storyline, :setup_guide]

    @valid_attrs %{
      name: "Guide 1"
    }
    @invalid_attrs %{
      name: nil
    }
    @valid_renaming %{
      name: "renamed guide name"
    }
    @invalid_renaming %{
      name: nil
    }

    test "list_guides/1 returns all of the storylines guides ordered by priority", %{
      public_storyline: public_storyline,
      guide: guide_1,
      member: member
    } do
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert [guide_1, guide_2, guide_3] == Annotations.list_guides(public_storyline.id)
    end

    test "get_guide!/1 returns the guide with given storyline id", %{
      guide: guide
    } do
      assert %Guide{} = Annotations.get_guide!(guide.id)
    end

    test "create_guide/1 with valid data creates a guide for a storyline that already has 1 guide",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      assert {:ok, %Guide{} = created_guide} =
               Annotations.create_guide(
                 public_storyline.id,
                 @valid_attrs,
                 member
               )

      assert created_guide.priority == 1
    end

    test "create_guide/1 with valid data creates a guide for a storyline that has no guides yet",
         %{
           member: member
         } do
      {:ok, storyline_without_guides} =
        Api.Storylines.create_public_storyline(
          %{name: Api.FixtureSequence.next("storyline_"), is_public: true},
          member
        )

      assert {:ok, %Guide{} = created_guide} =
               Annotations.create_guide(
                 storyline_without_guides.id,
                 @valid_attrs,
                 member
               )

      assert created_guide.priority == 0
    end

    test "create_guide/1 with invalid data fails", %{
      public_storyline: public_storyline,
      member: member
    } do
      assert {:error, %Ecto.Changeset{}} =
               Annotations.create_guide(public_storyline.id, @invalid_attrs, member)
    end

    test "rename_guide/2 with valid name renames a guide", %{
      guide: guide,
      member: member
    } do
      assert guide.name == @valid_attrs[:name]

      assert {:ok, %Guide{} = guide} =
               Annotations.rename_guide(guide, @valid_renaming[:name], member)

      assert guide.name == @valid_renaming[:name]
    end

    test "rename_guide/2 with invalid data fails", %{
      guide: guide,
      member: member
    } do
      assert {:error, %Ecto.Changeset{}} =
               Annotations.rename_guide(guide, @invalid_renaming[:name], member)
    end

    test "delete_guide/1 deletes the guide", %{
      public_storyline: public_storyline,
      guide: _guide_1,
      member: member
    } do
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, _guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert {:ok, %{} = _multi_map} = Annotations.delete_guide(guide_2, member)

      guides = public_storyline.id |> Annotations.list_guides()
      refute guide_2 in guides
    end

    test "delete_guide/1 deletes the guide and repositions other guides", %{
      public_storyline: public_storyline,
      guide: guide_1,
      member: member
    } do
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert guide_1.priority == 0
      assert guide_2.priority == 1
      assert guide_3.priority == 2

      assert {:ok, %{} = _multi_map} = Annotations.delete_guide(guide_2, member)

      guides = public_storyline.id |> Annotations.list_guides()

      refute guide_2 in guides

      updated_guide_1 = Annotations.get_guide!(guide_1.id)
      updated_guide_3 = Annotations.get_guide!(guide_3.id)

      assert updated_guide_1.priority == 0
      assert updated_guide_3.priority == 1
    end

    test "reposition_guide/2 moves the guide to a new priority if it's lower than its current",
         %{
           public_storyline: public_storyline,
           guide: guide_1,
           member: member
         } do
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert guide_1.priority == 0
      assert guide_2.priority == 1
      assert guide_3.priority == 2

      {:ok, %{"0" => updated_guide_2}} = Annotations.reposition_guide(guide_2.id, 0, member)

      updated_guide_1 = Annotations.get_guide!(guide_1.id)
      updated_guide_3 = Annotations.get_guide!(guide_3.id)

      assert updated_guide_1.priority == 1
      assert updated_guide_2.priority == 0
      assert updated_guide_3.priority == 2
    end

    test "reposition_guide/2 moves the guide to a new priority if it's higher than its current",
         %{
           public_storyline: public_storyline,
           guide: guide_1,
           member: member
         } do
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert guide_1.priority == 0
      assert guide_2.priority == 1
      assert guide_3.priority == 2

      {:ok, %{"2" => updated_guide_1}} = Annotations.reposition_guide(guide_1.id, 2, member)

      updated_guide_2 = Annotations.get_guide!(guide_2.id)
      updated_guide_3 = Annotations.get_guide!(guide_3.id)

      assert updated_guide_1.priority == 2
      assert updated_guide_2.priority == 0
      assert updated_guide_3.priority == 1
    end

    test "reposition_guide/2 fails if it tries to move to an out of bounds positive priority",
         %{
           public_storyline: public_storyline,
           guide: _guide_1,
           member: member
         } do
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, _guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert {:error, "The new priority position is out of bounds"} =
               Annotations.reposition_guide(guide_2.id, 10, member)
    end

    test "reposition_guide/2 fails if it tries to move to an out of bounds negative priority",
         %{
           public_storyline: public_storyline,
           guide: _guide_1,
           member: member
         } do
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, _guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      {:error, _errored_operation, %Ecto.Changeset{} = errored_changeset, _changes_so_far} =
        Annotations.reposition_guide(guide_2.id, -2, member)

      assert Enum.empty?(errored_changeset.errors) == false
      assert errored_changeset.valid? == false
    end
  end

  describe "annotations" do
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
    @valid_point_attrs_with_overlay %{
      kind: :point,
      message: "some message",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z",
      frame_selectors: ["iframe"],
      css_selector: "some css selector",
      anchor: :top,
      settings: %{show_dim: true}
    }
    @update_point_attrs %{
      kind: :point,
      message: "some updated message",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some updated message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z",
      frame_selectors: ["updated", "iframe"],
      css_selector: "some updated css selector",
      anchor: :right
    }
    @update_point_with_empty_message_attrs %{
      kind: :point,
      message: "",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some updated message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z",
      frame_selectors: ["updated", "iframe"],
      css_selector: "some updated css selector",
      anchor: :right
    }
    @invalid_point_attrs %{
      kind: nil,
      message: nil,
      rich_text: nil,
      last_edited: "2010-04-17T14:00:00Z",
      frame_selectors: nil,
      css_selector: nil,
      anchor: nil
    }

    @valid_modal_attrs %{
      kind: :modal,
      message: "some message",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z"
    }
    @update_modal_attrs %{
      kind: :modal,
      message: "some updated message",
      rich_text: %{
        "delta" => %{"ops" => [%{"insert" => "some updated message"}, %{"insert" => "\n"}]},
        "version" => "QuillDelta_20211027"
      },
      last_edited: "2010-04-17T14:00:00Z"
    }
    @invalid_modal_attrs %{
      kind: nil,
      message: nil,
      rich_text: nil,
      last_edited: "2010-04-17T14:00:00Z"
    }

    test "get_annotation!/1 returns annotation by id", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      annotation = annotation_point_fixture(guide, screen.id, member)

      assert Annotations.get_annotation!(annotation.id) != nil
    end

    test "list_guide_annotations/1 returns all annotations for a given guide, ordered", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point = annotation_point_fixture(guide, screen.id, member)
      modal = annotation_modal_fixture(guide, screen.id, member)

      assert Annotation.all_guide_annotations_query(guide.id) |> Repo.all() == [point, modal]
      assert point.step == 0
      assert modal.step == 1
    end

    test "add_annotation_to_guide/3 with valid data and kind :point adds a point annotation to a given guide",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point_attrs = Enum.into(%{screen_id: screen.id}, @valid_point_attrs)

      assert {:ok, %Annotation{} = point} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      assert(Annotation.all_guide_annotations_query(guide.id) |> Repo.all() == [point])
      assert point.kind == :point
      assert point.guide_id == guide.id
    end

    test "add_annotation_to_guide/3 valid data and with overlay and kind :point adds a point annotation to a given guide",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point_attrs = Enum.into(%{screen_id: screen.id}, @valid_point_attrs_with_overlay)

      assert {:ok, %Annotation{} = point} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      assert(Annotation.all_guide_annotations_query(guide.id) |> Repo.all() == [point])
      assert point.guide_id == guide.id
      assert point.settings.show_dim == true
    end

    test "add_annotation_to_guide/3 with valid data with step attribute and kind :point adds a point annotation to a given guide and pushing all subsequent annotations 1 step forward",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point_attrs = Enum.into(%{screen_id: screen.id}, @valid_point_attrs)

      {:ok, %Annotation{} = point0} =
        Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      {:ok, %Annotation{} = point1} =
        Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      {:ok, %Annotation{} = point2} =
        Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      point_attrs_with_step = Enum.into(%{step: point1.step}, point_attrs)

      assert {:ok, %{"create_annotation" => %Annotation{} = new_point1}} =
               Annotations.add_annotation_to_guide(
                 guide.id,
                 point_attrs_with_step,
                 :point,
                 member
               )

      [refreshed_point0, refreshed_point1, refreshed_point2, refreshed_point3] =
        Annotation.all_guide_annotations_query(guide.id)
        |> Repo.all()

      assert(
        [refreshed_point0.id, refreshed_point1.id, refreshed_point2.id, refreshed_point3.id] == [
          point0.id,
          new_point1.id,
          point1.id,
          point2.id
        ]
      )

      assert new_point1.id == refreshed_point1.id
      assert new_point1.step == 1
      assert point1.id == refreshed_point2.id
      assert refreshed_point2.step == 2
      assert point2.id == refreshed_point3.id
      assert refreshed_point3.step == 3
    end

    test "add_annotation_to_guide/3 with valid modal data and kind :point returns error changeset",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point_attrs = Enum.into(%{screen_id: screen.id}, @valid_modal_attrs)

      assert {:error, %Ecto.Changeset{}} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)
    end

    test "add_annotation_to_guide/3 with valid data and kind :point and with annotation settings adds a point annotation with settings to a given guide",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens

      point_attrs =
        Enum.into(
          %{
            screen_id: screen.id,
            settings: %{
              show_main_button: false,
              main_button_text: "n3xT",
              show_dismiss_button: false,
              show_back_button: false,
              show_avatar: true,
              avatar_url: "https://www.walnut.io",
              avatar_title: "Paz from Walnut",
              show_dim: true,
              size: :small
            }
          },
          @valid_point_attrs
        )

      assert {:ok, %Annotation{} = point} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      assert(Annotation.all_guide_annotations_query(guide.id) |> Repo.all() == [point])
      assert point.kind == :point
      assert point.guide_id == guide.id
      assert point.settings.show_main_button == false
      assert point.settings.main_button_text == "n3xT"
      assert point.settings.show_dismiss_button == false
      assert point.settings.show_back_button == false
      assert point.settings.show_avatar == true
      assert point.settings.avatar_url == "https://www.walnut.io"
      assert point.settings.avatar_title == "Paz from Walnut"
      assert point.settings.show_dim == true
      assert point.settings.size == :small
    end

    test "add_annotation_to_guide/3 with valid data and kind :modal and with annotation settings adds a point annotation with settings to a given guide",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens

      modal_attrs =
        Enum.into(
          %{
            screen_id: screen.id,
            settings: %{
              show_main_button: false,
              main_button_text: "n3xT",
              show_dismiss_button: false,
              show_back_button: false,
              show_avatar: true,
              avatar_url: "https://www.walnut.io",
              avatar_title: "Paz from Walnut",
              show_dim: true,
              size: :small
            }
          },
          @valid_modal_attrs
        )

      assert {:ok, %Annotation{} = modal} =
               Annotations.add_annotation_to_guide(guide.id, modal_attrs, :modal, member)

      assert(Annotation.all_guide_annotations_query(guide.id) |> Repo.all() == [modal])
      assert modal.kind == :modal
      assert modal.guide_id == guide.id
      assert modal.settings.show_main_button == false
      assert modal.settings.main_button_text == "n3xT"
      assert modal.settings.show_dismiss_button == false
      assert modal.settings.show_back_button == false
      assert modal.settings.show_avatar == true
      assert modal.settings.avatar_url == "https://www.walnut.io"
      assert modal.settings.avatar_title == "Paz from Walnut"
      assert modal.settings.show_dim == true
      assert modal.settings.size == :small
    end

    test "add_annotation_to_guide/3 with invalid data and kind :point returns error changeset", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point_attrs = Enum.into(%{screen_id: screen.id}, @invalid_point_attrs)

      assert {:error, %Ecto.Changeset{}} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)
    end

    test "add_annotation_to_guide/3 with valid data and kind :modal adds a modal annotation to a given guide",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      modal_attrs = Enum.into(%{screen_id: screen.id}, @valid_modal_attrs)

      assert {:ok, %Annotation{} = modal} =
               Annotations.add_annotation_to_guide(guide.id, modal_attrs, :modal, member)

      assert(Annotation.all_guide_annotations_query(guide.id) |> Repo.all() == [modal])
      assert modal.kind == :modal
      assert modal.guide_id == guide.id
    end

    test "add_annotation_to_guide/3 with valid data with step and kind :modal attribute adds a modal annotation to a given guide and pushing all subsequent annotations 1 step forward",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      modal_attrs = Enum.into(%{screen_id: screen.id}, @valid_modal_attrs)

      {:ok, %Annotation{} = modal0} =
        Annotations.add_annotation_to_guide(guide.id, modal_attrs, :modal, member)

      {:ok, %Annotation{} = modal1} =
        Annotations.add_annotation_to_guide(guide.id, modal_attrs, :modal, member)

      {:ok, %Annotation{} = modal2} =
        Annotations.add_annotation_to_guide(guide.id, modal_attrs, :modal, member)

      modal_attrs_with_step = Enum.into(%{step: modal1.step}, modal_attrs)

      assert {:ok, %{"create_annotation" => %Annotation{} = new_modal1}} =
               Annotations.add_annotation_to_guide(
                 guide.id,
                 modal_attrs_with_step,
                 :modal,
                 member
               )

      [refreshed_modal0, refreshed_modal1, refreshed_modal2, refreshed_modal3] =
        Annotation.all_guide_annotations_query(guide.id)
        |> Repo.all()

      assert(
        [refreshed_modal0.id, refreshed_modal1.id, refreshed_modal2.id, refreshed_modal3.id] == [
          modal0.id,
          new_modal1.id,
          modal1.id,
          modal2.id
        ]
      )

      assert new_modal1.id == refreshed_modal1.id
      assert new_modal1.step == 1
      assert modal1.id == refreshed_modal2.id
      assert refreshed_modal2.step == 2
      assert modal2.id == refreshed_modal3.id
      assert refreshed_modal3.step == 3
    end

    test "add_annotation_to_guide/3 with valid point data and kind :modal adds a modal annotation to a given guide",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      modal_attrs = Enum.into(%{screen_id: screen.id}, @valid_point_attrs)

      assert {:ok, %Annotation{} = modal} =
               Annotations.add_annotation_to_guide(guide.id, modal_attrs, :modal, member)

      assert(Annotation.all_guide_annotations_query(guide.id) |> Repo.all() == [modal])
      assert modal.kind == :modal
    end

    test "add_annotation_to_guide/3 with invalid data and kind :modal returns error changeset", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      modal_attrs = Enum.into(%{screen_id: screen.id}, @invalid_modal_attrs)

      assert {:error, %Ecto.Changeset{}} =
               Annotations.add_annotation_to_guide(guide.id, modal_attrs, :modal, member)
    end

    test "update_annotation/2 with valid data updates the annotation", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen1, screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point = annotation_point_fixture(guide, screen1.id, member)
      modal = annotation_modal_fixture(guide, screen1.id, member)

      point_update_attrs =
        Enum.into(
          %{
            screen_id: screen2.id,
            settings: %{
              show_main_button: false,
              main_button_text: "n3xT",
              show_dismiss_button: false,
              show_back_button: false,
              show_avatar: true,
              avatar_url: "https://www.walnut.io",
              avatar_title: "Paz from Walnut",
              show_dim: true,
              size: :small
            }
          },
          @update_point_attrs
        )

      modal_update_attrs =
        Enum.into(
          %{
            screen_id: screen2.id,
            settings: %{
              show_main_button: false,
              main_button_text: "n3xT",
              show_dismiss_button: false,
              show_back_button: false,
              show_avatar: true,
              avatar_url: "https://www.walnut.io",
              avatar_title: "Paz from Walnut",
              show_dim: true,
              size: :small
            }
          },
          @update_modal_attrs
        )

      assert {:ok, %Annotation{} = point} =
               Annotations.update_annotation(point, point_update_attrs, member)

      assert {:ok, %Annotation{} = modal} =
               Annotations.update_annotation(modal, modal_update_attrs, member)

      assert point.screen_id == screen2.id
      assert point.message == point_update_attrs.message
      assert point.rich_text == point_update_attrs.rich_text
      assert point.anchor == point_update_attrs.anchor
      assert point.css_selector == point_update_attrs.css_selector
      assert point.frame_selectors == point_update_attrs.frame_selectors
      assert point.kind == :point
      assert point.step == 0
      assert point.settings.show_main_button == false
      assert point.settings.main_button_text == "n3xT"
      assert point.settings.show_dismiss_button == false
      assert point.settings.show_back_button == false
      assert point.settings.show_avatar == true
      assert point.settings.avatar_url == "https://www.walnut.io"
      assert point.settings.avatar_title == "Paz from Walnut"
      assert point.settings.show_dim == true
      assert point.settings.size == :small

      assert modal.screen_id == screen2.id
      assert modal.message == modal_update_attrs.message
      assert modal.rich_text == modal_update_attrs.rich_text
      assert modal.anchor == nil
      assert modal.css_selector == nil
      assert modal.frame_selectors == nil
      assert modal.kind == :modal
      assert modal.step == 1
      assert modal.settings.show_main_button == false
      assert modal.settings.main_button_text == "n3xT"
      assert modal.settings.show_dismiss_button == false
      assert modal.settings.show_back_button == false
      assert modal.settings.show_avatar == true
      assert modal.settings.avatar_url == "https://www.walnut.io"
      assert modal.settings.avatar_title == "Paz from Walnut"
      assert modal.settings.show_dim == true
      assert modal.settings.size == :small
    end

    test "update_annotation/2 with empty message updates the annotation with empty message", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen1, screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point = annotation_point_fixture(guide, screen1.id, member)
      modal = annotation_modal_fixture(guide, screen1.id, member)

      point_update_attrs =
        Enum.into(%{screen_id: screen2.id}, @update_point_with_empty_message_attrs)

      modal_update_attrs =
        Enum.into(%{screen_id: screen2.id}, @update_point_with_empty_message_attrs)

      assert {:ok, %Annotation{} = point} =
               Annotations.update_annotation(point, point_update_attrs, member)

      assert {:ok, %Annotation{} = modal} =
               Annotations.update_annotation(modal, modal_update_attrs, member)

      assert point.message == point_update_attrs.message
      assert modal.message == modal_update_attrs.message
    end

    test "update_annotation/2 with valid data and different kind updates the annotation", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen1, screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point = annotation_point_fixture(guide, screen1.id, member)
      modal = annotation_modal_fixture(guide, screen1.id, member)
      point_update_attrs = Enum.into(%{screen_id: screen2.id}, @update_point_attrs)
      modal_update_attrs = Enum.into(%{screen_id: screen2.id}, @update_modal_attrs)

      assert {:ok, %Annotation{} = modal_from_point} =
               Annotations.update_annotation(point, modal_update_attrs, member)

      assert {:ok, %Annotation{} = point_from_modal} =
               Annotations.update_annotation(modal, point_update_attrs, member)

      assert modal_from_point.screen_id == screen2.id
      assert modal_from_point.message == point_update_attrs.message
      assert modal_from_point.rich_text == point_update_attrs.rich_text
      assert modal_from_point.anchor == nil
      assert modal_from_point.css_selector == nil
      assert modal_from_point.frame_selectors == nil
      assert modal_from_point.kind == :modal
      assert modal_from_point.step == 0

      assert point_from_modal.screen_id == screen2.id
      assert point_from_modal.message == point_update_attrs.message
      assert point_from_modal.rich_text == point_update_attrs.rich_text
      assert point_from_modal.anchor == point_update_attrs.anchor
      assert point_from_modal.css_selector == point_update_attrs.css_selector
      assert point_from_modal.frame_selectors == point_update_attrs.frame_selectors
      assert point_from_modal.kind == :point
      assert point_from_modal.step == 1
    end

    test "update_annotation/2 with invalid data returns error changeset", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen1, screen2, _screen3, _screen4, _screen5] = default_flow.screens
      original_attrs = @valid_point_attrs
      annotation = annotation_point_fixture(guide, screen1.id, member, original_attrs)
      invalid_attrs = Enum.into(%{screen_id: screen2.id}, @invalid_point_attrs)

      assert {:error, %Ecto.Changeset{}} =
               Annotations.update_annotation(annotation, invalid_attrs, member)

      assert annotation.screen_id == screen1.id
      assert annotation.message == original_attrs.message
      assert annotation.rich_text == original_attrs.rich_text
      assert annotation.anchor == original_attrs.anchor
      assert annotation.css_selector == original_attrs.css_selector
      assert annotation.frame_selectors == original_attrs.frame_selectors
      assert annotation.kind == original_attrs.kind
      assert annotation.step == 0
    end

    test "delete_annotation/1 deletes the annotation", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      annotation = annotation_point_fixture(guide, screen.id, member)

      assert {:ok, %Annotation{}} = Annotations.delete_annotation(annotation, member)

      annotations = Annotation.all_guide_annotations_query(guide.id) |> Repo.all()
      refute annotation in annotations
    end

    test "delete_annotation/1 deletes the annotation and reposition other annotations", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      point_attrs = Enum.into(%{screen_id: screen.id}, @valid_point_attrs)

      assert {:ok, %Annotation{} = annotation0} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      assert {:ok, %Annotation{} = annotation1} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      assert {:ok, %Annotation{} = annotation2} =
               Annotations.add_annotation_to_guide(guide.id, point_attrs, :point, member)

      assert annotation0.step == 0
      assert annotation1.step == 1
      assert annotation2.step == 2

      assert {:ok, %Annotation{}} = Annotations.delete_annotation(annotation1, member)

      annotations = Annotation.all_guide_annotations_query(guide.id) |> Repo.all()

      refute annotation1 in annotations
      assert annotations |> Enum.at(0) |> Map.get(:step) == 0
      assert annotations |> Enum.at(1) |> Map.get(:step) == 1
    end

    test "delete_annotations_in_screen/1 deletes annotations per screen and reposition other annotations",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen1, screen2, screen3, _screen4, _screen5] = default_flow.screens
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

      Annotations.delete_annotations_in_screen(screen1.id)

      annotations = Annotation.all_guide_annotations_query(guide.id) |> Repo.all()

      refute annotation0 in annotations
      refute annotation2 in annotations
      assert annotation1 in annotations
      assert annotation3 in annotations
    end

    test "reposition_annotation/2 moves the annotation to new position if it's lower than its current",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens

      annotation_1 = annotation_point_fixture(guide, screen.id, member)
      annotation_2 = annotation_point_fixture(guide, screen.id, member)
      annotation_3 = annotation_point_fixture(guide, screen.id, member)

      assert annotation_1.step == 0
      assert annotation_2.step == 1
      assert annotation_3.step == 2

      {:ok, %{"0" => annotation_2}} =
        Annotations.reposition_annotation(annotation_2.id, 0, member)

      annotation_1 = Repo.get(Annotation, annotation_1.id)
      annotation_3 = Repo.get(Annotation, annotation_3.id)

      assert annotation_1.step == 1
      assert annotation_2.step == 0
      assert annotation_3.step == 2
    end

    test "reposition_annotation/2 moves the annotation to new position if it's higher than its current",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens

      annotation_1 = annotation_point_fixture(guide, screen.id, member)
      annotation_2 = annotation_point_fixture(guide, screen.id, member)
      annotation_3 = annotation_point_fixture(guide, screen.id, member)

      assert annotation_1.step == 0
      assert annotation_2.step == 1
      assert annotation_3.step == 2

      {:ok, %{"2" => annotation_1}} =
        Annotations.reposition_annotation(annotation_1.id, 2, member)

      annotation_2 = Repo.get(Annotation, annotation_2.id)
      annotation_3 = Repo.get(Annotation, annotation_3.id)

      assert annotation_1.step == 2
      assert annotation_2.step == 0
      assert annotation_3.step == 1
    end

    test "reposition_annotation/2 fails if it tries to move to an out of bounds positive position",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens

      annotation_point_fixture(guide, screen.id, member)
      last_annotation = annotation_point_fixture(guide, screen.id, member)

      assert {:error, "The new step position is out of bounds"} =
               Annotations.reposition_annotation(last_annotation.id, 10, member)
    end

    test "reposition_annotation/2 fails if it tries to move to an out of bounds negative position",
         %{
           default_flow: default_flow,
           guide: guide,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens

      annotation_point_fixture(guide, screen.id, member)
      last_annotation = annotation_point_fixture(guide, screen.id, member)

      {:error, _errored_operation, %Ecto.Changeset{} = errored_changeset, _changes_so_far} =
        Annotations.reposition_annotation(last_annotation.id, -2, member)

      assert Enum.empty?(errored_changeset.errors) == false
      assert errored_changeset.valid? == false
    end
  end

  describe "position_field_for_entity/1" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :setup_guide,
      :get_default_flow
    ]

    test "when called with entity %Annotation{} it returns :step", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      annotation_1 = annotation_point_fixture(guide, screen.id, member)

      assert :step ==
               Annotations.position_field_for_entity(annotation_1)
    end

    test "when called with an unsupported entity it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        Annotations.position_field_for_entity(%Flow{})
      end
    end
  end

  describe "position_field_for_entity_type/1" do
    test "when called with entity_type Annotation it returns :step" do
      assert :step ==
               Annotations.position_field_for_entity_type(Annotation)
    end

    test "when called with an unsupported entity_tyoe it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        Annotations.position_field_for_entity(Api.Storylines.Storyline)
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
      :setup_guide,
      :get_default_flow
    ]

    test "when called with entity %Annotation{} it returns all the entity's siblings", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      annotation_1 = annotation_point_fixture(guide, screen.id, member) |> Repo.preload(:guide)
      annotation_2 = annotation_point_fixture(guide, screen.id, member)

      received_annotations = Annotations.get_entities_to_reposition(annotation_1)

      assert Enum.map(received_annotations, fn annotation -> annotation.id end) == [
               annotation_1.id,
               annotation_2.id
             ]
    end

    test "when called with an unsupported entity it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        Annotations.get_entities_to_reposition(%Api.Storylines.Storyline{})
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
      :setup_guide,
      :get_default_flow
    ]

    test "when called with entity %Annotation{}", %{
      default_flow: default_flow,
      guide: guide,
      member: member
    } do
      default_flow = get_flow_with_preloaded_ordered_screens(default_flow.id)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      annotation_1 = annotation_point_fixture(guide, screen.id, member)
      expected_func = &Annotation.reposition_changeset/2

      assert expected_func ==
               Annotations.reposition_changeset_func_for_entity(annotation_1)
    end

    test "when called with an unsupported entity it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        Annotations.reposition_changeset_func_for_entity(%Api.Storylines.Storyline{})
      end
    end
  end

  describe "reposition_changeset_func_for_entity_type/1" do
    test "when called with entity_type Annotation" do
      expected_func = &Annotation.reposition_changeset/2

      assert expected_func ==
               Annotations.reposition_changeset_func_for_entity_type(Annotation)
    end

    test "when called with an unsupported entity it raises an exception" do
      assert_raise FunctionClauseError, fn ->
        Annotations.reposition_changeset_func_for_entity_type(Api.Storylines.Storyline)
      end
    end
  end

  defp get_flow_with_preloaded_ordered_screens(flow_id) do
    Repo.get!(Flow, flow_id)
    |> Repo.preload(screens: [flow_screen: FlowScreen.order_by_position_query()])
  end
end
