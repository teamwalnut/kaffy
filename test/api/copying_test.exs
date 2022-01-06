defmodule Api.CopyingTest do
  use Api.DataCase, async: true

  alias Api.Annotations
  alias Api.Annotations.Annotation
  alias Api.Storylines
  alias Api.Storylines.Editing
  alias Api.Storylines.Editing.Edit
  alias Api.Storylines.ScreenGroupingFixtures
  alias Api.Storylines.SmartObjects

  setup [
    :setup_user,
    :setup_company,
    :setup_member,
    :setup_public_storyline,
    :setup_guide,
    :setup_storyline_html_patch
  ]

  @edit_override %{
    "dom_selector" => nil,
    "css_selector" => "div > .newText",
    "frame_selectors" => ["iframe"],
    "kind" => "text",
    "last_edited_at" => "2021-02-21T15:44:56.868Z",
    "text_edit_props" => %{
      "original_text" => "original text",
      "text" => "NEW OVERRIDE"
    },
    "binding_edit_props" => nil,
    "change_image_edit_props" => nil,
    "html_edit_props" => nil,
    "link_edit_props" => nil,
    "scroll_edit_props" => nil,
    "style_edit_props" => nil,
    "inserted_at" => nil,
    "updated_at" => nil,
    "screen_id" => nil
  }

  describe "Copying" do
    def member_for_company_fixture(company, attrs \\ %{}) do
      user = user_fixture()

      {:ok, member} = Api.Companies.add_member(user.id, company, attrs)
      member
    end

    test "copy_storyline/2 clones the storyline successfuly when there are no screens", %{
      company: company,
      public_storyline: public_storyline
    } do
      member2 = member_for_company_fixture(company)

      assert {:ok, copied_storyline} =
               Api.Copying.copy_storyline(member2.id, public_storyline, member2)

      assert copied_storyline.is_public == false
      assert copied_storyline.name == "Copy of #{public_storyline.name}"
    end

    test "copy_storyline/2 clones the storyline successfuly preserving screens", %{
      company: company,
      public_storyline: public_storyline
    } do
      member2 = member_for_company_fixture(company)

      screen1 = Api.StorylinesFixtures.screen_fixture(public_storyline)

      _text_edit =
        Api.EditingFixtures.text_edit_fixture(screen1.id, %{
          :original_text => "dd",
          :text => "new new"
        })

      screen2 = Api.StorylinesFixtures.screen_fixture(public_storyline)
      _style_edit = Api.EditingFixtures.style_edit_fixture(screen2.id)
      _screen_link_edit = Api.EditingFixtures.screen_link_edit_fixture(screen1.id, screen2.id)
      _url_link_edit = Api.EditingFixtures.url_link_edit_fixture(screen1.id)

      screens = [screen2, screen1]

      public_storyline =
        Api.Storylines.get_storyline!(public_storyline.id) |> Api.Repo.preload(:start_screen)

      assert {:ok, copied_storyline} =
               Api.Copying.copy_storyline(member2.id, public_storyline, member2)

      copied_storyline =
        Api.Storylines.get_storyline!(copied_storyline.id)
        |> Api.Repo.preload([:screens, :start_screen])

      assert copied_storyline.is_public == false
      assert copied_storyline.name == "Copy of #{public_storyline.name}"

      assert copied_storyline.start_screen_id != screen1.id
      assert copied_storyline.start_screen.name == screen1.name
      assert copied_storyline.screens |> Enum.count() == screens |> Enum.count()

      assert copied_storyline.screens
             |> Enum.at(0)
             |> Repo.preload(:edits)
             |> Map.get(:edits)
             |> Enum.count() == 3

      assert copied_storyline.screens
             |> Enum.at(1)
             |> Repo.preload(:edits)
             |> Map.get(:edits)
             |> Enum.count() == 1

      copied_storyline.screens
      |> Enum.each(fn current_screen ->
        assert current_screen.storyline_id == copied_storyline.id
      end)
    end

    test "copy_storyline/2 copies the storyline with patches", %{
      member: member,
      public_storyline: public_storyline,
      storyline_html_patch: original_storyline_html_patch
    } do
      assert {:ok, copied_storyline} =
               Api.Copying.copy_storyline(member.id, public_storyline, member)

      cloned_patches = Api.Patching.list_storyline_patches(copied_storyline.id)
      cloned_patches_datas = cloned_patches |> Enum.map(fn p -> p.data end)
      assert original_storyline_html_patch.data in cloned_patches_datas
    end

    test "copy_storyline/2 copies the storyline with flows", %{
      member: member,
      public_storyline: public_storyline
    } do
      _screen1 = screen_fixture(public_storyline)

      _default_flow = default_flow_fixture(public_storyline.id)

      second_flow = flow_fixture(public_storyline.id)
      screen2 = screen_in_flow_fixture(public_storyline, second_flow)

      assert {:ok, copied_storyline} =
               Api.Copying.copy_storyline(member.id, public_storyline, member)

      copied_storyline = copied_storyline |> Repo.preload(default_flow: [:screens])

      cloned_second_flow =
        Api.Storylines.list_flows(copied_storyline.id) |> Enum.at(1) |> Repo.preload([:screens])

      assert copied_storyline.default_flow.screens |> Enum.count() == 1
      assert Api.Storylines.list_flows(copied_storyline.id) |> Enum.count() == 2

      assert cloned_second_flow.screens |> Enum.count() == 1
      assert cloned_second_flow.screens |> Enum.at(0) |> Map.get(:name) == screen2.name
    end

    test "copy_storyline/2 copies the storyline and copies guides and annotations", %{
      member: member,
      public_storyline: public_storyline,
      guide: original_guide_1
    } do
      screen_1 = screen_fixture(public_storyline)
      screen_2 = screen_fixture(public_storyline)

      original_guide_1_annotation =
        annotation_point_fixture(original_guide_1, screen_1.id, member, %{
          settings: %{show_main_button: false}
        })

      {:ok, original_guide_2} =
        Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)

      original_guide_2_annotation =
        annotation_modal_fixture(original_guide_2, screen_2.id, member)

      assert {:ok, copied_storyline} =
               Api.Copying.copy_storyline(member.id, public_storyline, member)

      copied_storyline = copied_storyline |> Repo.preload(default_flow: [:screens])

      copied_screen_1 = copied_storyline.default_flow.screens |> Enum.at(0)
      copied_screen_2 = copied_storyline.default_flow.screens |> Enum.at(1)

      copied_guides = Annotations.list_guides(copied_storyline.id)
      copied_guide_1 = copied_guides |> Enum.at(0)

      copied_guide_1_annotation =
        Annotation.all_guide_annotations_query(copied_guide_1.id) |> Repo.all() |> Enum.at(0)

      copied_guide_2 = copied_guides |> Enum.at(1)

      copied_guide_2_annotation =
        Annotation.all_guide_annotations_query(copied_guide_2.id) |> Repo.all() |> Enum.at(0)

      assert copied_guide_1.name == original_guide_1.name
      assert copied_guide_1.priority == original_guide_1.priority

      assert copied_guide_1_annotation.kind == original_guide_1_annotation.kind
      assert copied_guide_1_annotation.message == original_guide_1_annotation.message
      assert copied_guide_1_annotation.step == original_guide_1_annotation.step
      assert copied_guide_1_annotation.css_selector == original_guide_1_annotation.css_selector

      assert copied_guide_1_annotation.frame_selectors ==
               original_guide_1_annotation.frame_selectors

      assert copied_guide_1_annotation.anchor == original_guide_1_annotation.anchor
      assert copied_guide_1_annotation.screen_id == copied_screen_1.id
      assert copied_guide_1_annotation.guide_id == copied_guide_1.id
      assert copied_guide_1_annotation.settings == original_guide_1_annotation.settings

      assert copied_guide_2.name == original_guide_2.name
      assert copied_guide_2.priority == original_guide_2.priority

      assert copied_guide_2_annotation.kind == original_guide_2_annotation.kind
      assert copied_guide_2_annotation.message == original_guide_2_annotation.message
      assert copied_guide_2_annotation.step == original_guide_2_annotation.step
      assert copied_guide_2_annotation.css_selector == original_guide_2_annotation.css_selector

      assert copied_guide_2_annotation.frame_selectors ==
               original_guide_2_annotation.frame_selectors

      assert copied_guide_2_annotation.anchor == original_guide_2_annotation.anchor
      assert copied_guide_2_annotation.screen_id == copied_screen_2.id
      assert copied_guide_2_annotation.guide_id == copied_guide_2.id
      assert copied_guide_2_annotation.settings == original_guide_2_annotation.settings
    end

    test "copy_storyline/2 correctly copies link-edits", %{
      member: member,
      public_storyline: public_storyline
    } do
      screen1 = screen_fixture(public_storyline)
      screen2 = screen_fixture(public_storyline)

      Editing.add_edit(screen1.id, %{
        kind: :link,
        dom_selector: nil,
        css_selector: "first",
        link_edit_props: %{destination: %{kind: "screen", id: screen2.id}},
        last_edited_at: DateTime.utc_now()
      })

      Editing.add_edit(screen1.id, %{
        kind: :link,
        dom_selector: nil,
        css_selector: "second",
        link_edit_props: %{destination: %{kind: "screen", id: screen2.id}},
        last_edited_at: DateTime.utc_now()
      })

      Editing.add_edit(screen2.id, %{
        kind: :link,
        dom_selector: nil,
        css_selector: "some css",
        link_edit_props: %{destination: %{kind: "screen", id: screen1.id}},
        last_edited_at: DateTime.utc_now()
      })

      assert {:ok, copied_storyline} =
               Api.Copying.copy_storyline(member.id, public_storyline, member)

      copied_storyline = copied_storyline |> Repo.preload(default_flow: [:screens])

      copied_screen1 = copied_storyline.default_flow.screens |> Enum.at(0)
      copied_screen2 = copied_storyline.default_flow.screens |> Enum.at(1)

      assert Editing.list_edits(copied_screen1.id) |> Enum.count() == 2
      assert Editing.list_edits(copied_screen2.id) |> Enum.count() == 1

      edit1 = Editing.list_edits(copied_screen1.id) |> Enum.at(0)
      edit2 = Editing.list_edits(copied_screen1.id) |> Enum.at(1)
      edit3 = Editing.list_edits(copied_screen2.id) |> Enum.at(0)

      assert edit1.css_selector == "first"
      assert edit2.css_selector == "second"
      assert edit1.link_edit_props.destination.id == copied_screen2.id
      assert edit3.link_edit_props.destination.id == copied_screen1.id
    end

    test "copy_storyline/2 copies the storyline with its settings", %{
      member: member,
      public_storyline: public_storyline
    } do
      {:ok, original_settings} =
        Api.Settings.update_storyline_settings(
          public_storyline.id,
          %{
            main_color: "#123456",
            secondary_color: "#abcdef"
          },
          member
        )

      assert {:ok, copied_storyline} =
               Api.Copying.copy_storyline(member.id, public_storyline, member)

      copied_storyline = copied_storyline |> Repo.preload(:settings)
      copied_storyline_settings = copied_storyline.settings
      assert copied_storyline_settings.main_color == original_settings.main_color
      assert copied_storyline_settings.secondary_color == original_settings.secondary_color
    end

    test "copy_storyline/2 copies the storyline with its smart object classes", %{
      member: member,
      public_storyline: storyline
    } do
      _screen_1 = screen_fixture(storyline, name: "screen1")
      screen_2 = screen_fixture(storyline, name: "screen2")

      SmartObjects.create_class(class_with_link_edit(storyline.id, screen_2.id), member)
      storyline = storyline |> Repo.preload(:smart_object_classes)

      {:ok, copied_storyline} = Api.Copying.copy_storyline(member.id, storyline, member)

      copied_storyline = copied_storyline |> Repo.preload(:smart_object_classes)

      # assert classes storyline association was successfully remapped during copying
      for class <- copied_storyline.smart_object_classes do
        assert class.storyline_id == copied_storyline.id
      end

      # assert normalized copied classes data equality
      origin_classes = storyline.smart_object_classes |> SmartObjects.Class.to_attributes()
      copied_classes = copied_storyline.smart_object_classes |> SmartObjects.Class.to_attributes()

      for {origin_class, copied_class} <- Enum.zip(origin_classes, copied_classes) do
        origin_class_data =
          origin_class
          |> Map.delete("id")
          |> Map.delete("storyline_id")
          |> Map.delete("inserted_at")
          |> Map.delete("updated_at")
          |> Map.delete("last_edited_at")

        origin_class_data =
          origin_class_data["edits"]
          |> Enum.map(fn edit ->
            edit
            |> Map.delete("id")
            |> Map.delete("link_edit_props")
            |> Map.delete("last_edited_at")
          end)

        copied_class_data =
          copied_class
          |> Map.delete("id")
          |> Map.delete("storyline_id")
          |> Map.delete("inserted_at")
          |> Map.delete("updated_at")
          |> Map.delete("last_edited_at")

        copied_class_data =
          copied_class_data["edits"]
          |> Enum.map(fn edit ->
            edit
            |> Map.delete("id")
            |> Map.delete("link_edit_props")
            |> Map.delete("last_edited_at")
          end)

        assert origin_class_data == copied_class_data
      end
    end

    test "copy_storyline/2 it should remap related smart object instances correctly", %{
      member: member,
      public_storyline: storyline
    } do
      screen_1 = screen_fixture(storyline, name: "screen1")
      screen_2 = screen_fixture(storyline, name: "screen2")

      SmartObjects.create_class(class_with_link_edit(storyline.id, screen_2.id), member)

      storyline = storyline |> Repo.preload(:smart_object_classes)
      origin_class = storyline.smart_object_classes |> Enum.at(0)

      {:ok, _origin_instance} =
        SmartObjects.update_instances_in_screen(
          screen_1.id,
          [
            %{
              class_id: origin_class.id,
              edits_overrides: [
                @edit_override
              ]
            }
          ],
          member
        )

      {:ok, copied_storyline} = Api.Copying.copy_storyline(member.id, storyline, member)

      copied_storyline = copied_storyline |> Repo.preload([:screens, :smart_object_classes])
      copied_class = copied_storyline.smart_object_classes |> Enum.at(0)

      copied_screen_1 =
        copied_storyline.screens
        |> Enum.find(fn screen -> screen.name == "screen1" end)

      copied_instance = copied_screen_1.smart_object_instances |> Enum.at(0)

      copied_instance_link_edit =
        copied_instance.edits |> Enum.find(fn edit -> edit["kind"] == "link" end)

      copied_instance_override = copied_instance.edits_overrides |> Enum.at(0)

      copied_screen_2 =
        copied_storyline.screens
        |> Enum.find(fn screen -> screen.name == "screen2" end)

      assert copied_instance_override["css_selector"] == @edit_override["css_selector"]
      assert copied_instance.class_id == copied_class.id
      assert copied_instance.screen_id == copied_screen_1.id
      assert copied_instance_link_edit["screen_id"] == copied_screen_1.id

      assert copied_instance_link_edit["link_edit_props"]["destination"]["id"] ==
               copied_screen_2.id
    end

    test "copy_flow/2 with valid flow clones the flow correctly", %{
      public_storyline: storyline,
      member: member
    } do
      storyline2 = Api.StorylinesFixtures.public_storyline_fixture(member)

      flow_name = "unique_flow_name"

      {:ok, flow: flow} =
        ScreenGroupingFixtures.setup_flow(
          %{public_storyline: storyline},
          %{name: flow_name}
        )

      assert {:ok, _copied_flow} = storyline2 |> Api.Storylines.copy_flow(flow)

      storyline = storyline |> Api.Repo.preload(:flows, force: true)
      storyline2 = storyline2 |> Api.Repo.preload(:flows, force: true)

      assert Enum.count(storyline.flows) == 2
      assert Enum.count(storyline2.flows) == 2
      assert storyline.flows |> Enum.at(1) |> Map.get(:name) == flow_name
      assert storyline2.flows |> Enum.at(1) |> Map.get(:name) == flow_name
    end

    test "copy_screen/2 with valid screen clones the screen correctly", %{
      public_storyline: storyline,
      member: member
    } do
      screen = Api.StorylinesFixtures.screen_fixture(storyline) |> Repo.preload(:flow)

      text_edit =
        Api.EditingFixtures.text_edit_fixture(screen.id, %{
          :original_text => "original",
          :text => "text"
        })

      edits = [text_edit]

      assert {:ok, cloned_screen} = Api.Storylines.copy_screen(screen, screen.flow, %{}, member)

      cloned_screen = cloned_screen |> Api.Repo.preload(:edits)

      storyline = storyline |> Api.Repo.preload(:screens, force: true)

      assert Enum.count(storyline.screens) == 2
      assert cloned_screen.name == screen.name

      cloned_screen.edits
      |> Enum.with_index()
      |> Enum.each(fn {current_edit, i} ->
        assert current_edit.kind == Enum.at(edits, i).kind
      end)
    end

    test "copy_screen/2 with valid screen updated last edited of storyline", %{
      public_storyline: storyline,
      member: member
    } do
      screen = Api.StorylinesFixtures.screen_fixture(storyline) |> Repo.preload(:flow)
      current_datetime = DateTime.utc_now()
      assert {:ok, _cloned_screen} = Api.Storylines.copy_screen(screen, screen.flow, %{}, member)

      storyline = Storylines.get_storyline!(storyline.id)
      assert DateTime.compare(storyline.last_edited, current_datetime) == :gt
    end

    test "copy_screen/2 can copy to a different flow", %{
      public_storyline: storyline,
      member: member
    } do
      screen = screen_fixture(storyline) |> Repo.preload(:flow)
      second_flow = flow_fixture(storyline.id)

      assert {:ok, cloned_screen} = Api.Storylines.copy_screen(screen, second_flow, %{}, member)

      cloned_screen = cloned_screen |> Repo.preload(:flow)
      storyline = storyline |> Api.Repo.preload(:screens, force: true)

      assert Enum.count(storyline.screens) == 2
      assert cloned_screen.name == screen.name
      assert cloned_screen.flow == second_flow
    end

    test "copy_screen/2 with valid screen clones the screen correctly when dimensions is nil", %{
      public_storyline: storyline,
      member: member
    } do
      screen =
        screen_fixture(storyline, original_dimensions: nil)
        |> Repo.preload(:flow)

      text_edit =
        text_edit_fixture(screen.id, %{
          :original_text => "original",
          :text => "text"
        })

      edits = [text_edit]

      assert {:ok, cloned_screen} = Api.Storylines.copy_screen(screen, screen.flow, %{}, member)

      cloned_screen = cloned_screen |> Api.Repo.preload(:edits)

      storyline = storyline |> Api.Repo.preload(:screens, force: true)

      assert Enum.count(storyline.screens) == 2
      assert cloned_screen.name == screen.name

      cloned_screen.edits
      |> Enum.with_index()
      |> Enum.each(fn {current_edit, i} ->
        assert current_edit.kind == Enum.at(edits, i).kind
      end)
    end

    test "copy_screen/2 copies the screen with its instances", %{
      public_storyline: storyline,
      member: member
    } do
      screen = screen_fixture(storyline, name: "screen1")
      screen_2 = screen_fixture(storyline, name: "screen2")

      {:ok, class} =
        SmartObjects.create_class(class_with_link_edit(storyline.id, screen_2.id), member)

      SmartObjects.update_instances_in_screen(
        screen.id,
        [
          %{class_id: class.id, edits_overrides: [@edit_override]}
        ],
        member
      )

      origin_screen = screen |> Repo.reload()

      second_flow = flow_fixture(storyline.id)

      assert {:ok, cloned_screen} =
               Api.Storylines.copy_screen(origin_screen, second_flow, %{}, member)

      origin_instances = origin_screen.smart_object_instances |> Enum.map(&Map.from_struct(&1))
      copied_instances = cloned_screen.smart_object_instances |> Enum.map(&Map.from_struct(&1))

      # assert instances screen association was successfully remapped during copying
      copied_instances
      |> Enum.each(fn instance -> assert instance.screen_id == cloned_screen.id end)

      assert length(copied_instances) == length(origin_instances)

      # assert normalized copied instances data equality
      for {origin_instance, copied_instance} <- Enum.zip(origin_instances, copied_instances) do
        origin_instance_data = instance_cleanup(origin_instance)

        origin_instance_data = %{
          origin_instance_data
          | edits:
              origin_instance_data.edits
              |> Enum.map(
                &(Map.delete(&1, "id")
                  |> Map.delete("last_edited_at")
                  |> Map.delete("screen_id"))
              ),
            edits_overrides:
              origin_instance_data.edits_overrides
              |> Enum.map(fn e ->
                e
                |> Map.delete("id")
                |> Map.delete("last_edited_at")
                |> Map.delete("screen_id")
              end),
            dom_selector:
              origin_instance_data.dom_selector |> Map.from_struct() |> Map.delete(:id)
        }

        copied_instance_data = instance_cleanup(copied_instance)

        copied_instance_data = %{
          copied_instance_data
          | edits:
              copied_instance_data.edits
              |> Enum.map(fn edit ->
                edit =
                  edit
                  |> Map.delete("id")
                  |> Map.delete("last_edited_at")
                  |> Map.delete("screen_id")

                case edit["link_edit_props"] != nil do
                  true ->
                    %{
                      edit
                      | "link_edit_props" =>
                          edit["link_edit_props"] |> Map.delete("target_screen_id")
                    }

                  false ->
                    edit
                end
              end),
            edits_overrides:
              copied_instance_data.edits_overrides
              |> Enum.map(fn e ->
                e |> Map.delete("id") |> Map.delete("last_edited_at") |> Map.delete("screen_id")
              end),
            dom_selector:
              copied_instance_data.dom_selector |> Map.from_struct() |> Map.delete(:id)
        }

        assert origin_instance_data == copied_instance_data
      end
    end

    defp instance_cleanup(instance) do
      instance
      |> Map.delete(:id)
      |> Map.delete(:screen_id)
      |> Map.delete(:inserted_at)
      |> Map.delete(:updated_at)
    end

    defp class_with_link_edit(storyline_id, link_edit_to_scren_id) do
      %Api.Storylines.SmartObjects.Class{
        storyline_id: storyline_id,
        name: "test smart object",
        thumbnail: "===",
        css_selector: "div > div",
        dom_selector: %{
          xpath_node: "//div > p",
          xpath_frames: ["//iframe"]
        },
        edits: [
          %Edit{
            screen_id: nil,
            dom_selector: nil,
            css_selector: "div > .newText",
            frame_selectors: ["iframe"],
            kind: "text",
            last_edited_at: "2021-02-21T15:44:56.868Z",
            text_edit_props: %{
              original_text: "original text",
              text: "new text"
            },
            binding_edit_props: nil,
            change_image_edit_props: nil,
            html_edit_props: nil,
            link_edit_props: nil,
            scroll_edit_props: nil,
            style_edit_props: nil
          }
          |> Edit.to_map(),
          %Edit{
            dom_selector: nil,
            frame_selectors: ["iframe"],
            css_selector: "i.css.url",
            kind: "link",
            last_edited_at: "2021-02-21T15:44:56.868Z",
            link_edit_props: %{
              "destination" => %{
                "kind" => "screen",
                "id" => link_edit_to_scren_id,
                "delay_ms" => nil
              }
            },
            screen_id: nil,
            binding_edit_props: nil,
            change_image_edit_props: nil,
            html_edit_props: nil,
            scroll_edit_props: nil,
            style_edit_props: nil,
            text_edit_props: nil
          }
          |> Edit.to_map()
        ]
      }
    end
  end
end
