defmodule Api.Storylines.SmartObjectTest do
  use Api.DataCase, async: true
  alias Api.Repo
  alias Api.Storylines.SmartObjects
  alias Api.Storylines.SmartObjects.Class

  describe "smart object classes" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen
    ]

    @first_edit %{
      "css_selector" => ".first .edit",
      "frame_selectors" => ["iframe"],
      "domSelector" => %{
        "xpathNode" => "div > a",
        "xpathFrames" => ["xpath iframe"]
      },
      "last_edited_at" => "2021-02-21T15:44:56.868Z",
      "kind" => "TEXT",
      "text_edit_props" => %{
        "original_text" => "original text",
        "text" => "first edit text"
      }
    }

    @second_edit %{
      "domSelector" => %{
        "xpathNode" => "div > a",
        "xpathFrames" => ["xpath iframe"]
      },
      "css_selector" => ".second .edit",
      "frame_selectors" => ["iframe"],
      "last_edited_at" => "2021-02-21T15:44:56.868Z",
      "kind" => "TEXT",
      "text_edit_props" => %{
        "original_text" => "original text",
        "text" => "second edit text"
      }
    }

    @invalid_edit %{
      "domSelector" => %{
        "xpathNode" => "",
        "xpathFrames" => ["xpath iframe"]
      },
      "frame_selectors" => ["iframe"],
      "css_selector" => "",
      "last_edited_at" => "2021-02-21T15:44:56.868Z",
      "kind" => "TEXT",
      "text_edit_props" => %{
        "original_text" => "original text",
        "text" => "invalid edit text"
      }
    }

    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    test "list smart object classes should return an empty array", %{public_storyline: storyline} do
      {:ok, list} = SmartObjects.list_classes(storyline.id)
      assert list == []
    end

    test "create and retrieve smart object classes", %{
      public_storyline: storyline,
      member: member
    } do
      {:ok, smart_object_class} = SmartObjects.create_class(simple_class(storyline.id), member)

      {:ok, list} = SmartObjects.list_classes(storyline.id)
      assert list == [smart_object_class]
    end

    test "should throw error when trying to create invalid class", %{
      public_storyline: storyline,
      member: member
    } do
      {:error, error_changeset} = SmartObjects.create_class(invalid_class(storyline.id), member)

      assert error_changeset |> Map.get(:errors) |> Enum.at(0) ==
               {:edits, {"invalid edits", []}}
    end

    test "add smart object instance to a screen", %{
      public_storyline: storyline,
      screen: screen,
      member: member
    } do
      {:ok, smart_object_class} = SmartObjects.create_class(simple_class(storyline.id), member)

      class_id = smart_object_class.id

      SmartObjects.update_instances_in_screen(
        screen.id,
        [%{class_id: class_id}],
        member
      )

      screen = Repo.get!(Api.Storylines.Screen, screen.id)

      assert [
               %{
                 class_id: ^class_id,
                 edits: [
                   %{
                     "css_selector" => ".first .edit",
                     "domSelector" => %{
                       "xpathNode" => "div > a"
                     }
                   }
                 ]
               }
             ] = screen.smart_object_instances
    end

    test "add smart object instance to a screen with overrides", %{
      public_storyline: storyline,
      screen: screen,
      member: member
    } do
      {:ok, smart_object_class} = SmartObjects.create_class(simple_class(storyline.id), member)

      class_id = smart_object_class.id

      SmartObjects.update_instances_in_screen(
        screen.id,
        [%{class_id: class_id, edits_overrides: [@second_edit]}],
        member
      )

      screen = Repo.get!(Api.Storylines.Screen, screen.id)

      assert [
               %{
                 class_id: ^class_id,
                 edits: [
                   %{
                     "css_selector" => ".first .edit",
                     "domSelector" => %{
                       "xpathNode" => "div > a"
                     }
                   }
                 ],
                 edits_overrides: [%{"css_selector" => ".second .edit"}]
               }
             ] = screen.smart_object_instances
    end

    test "update smart object class", %{
      public_storyline: storyline,
      screen: screen,
      member: member
    } do
      {:ok, class} = SmartObjects.create_class(simple_class(storyline.id), member)
      class_id = class.id
      SmartObjects.update_instances_in_screen(screen.id, [%{class_id: class.id}], member)

      {:ok, _} =
        SmartObjects.update_class_and_its_instances(
          class,
          %{
            name: "new name",
            thumbnail: "new thumbnail",
            edits: [@second_edit]
          },
          member
        )

      {:ok, classes} = SmartObjects.list_classes(storyline.id)

      assert [
               %{
                 id: ^class_id,
                 name: "new name",
                 thumbnail: "new thumbnail",
                 edits: [%{"css_selector" => ".second .edit"}]
               }
             ] = classes

      screen = Repo.get!(Api.Storylines.Screen, screen.id)

      assert [
               %{
                 class_id: ^class_id,
                 edits: [
                   %{
                     "css_selector" => ".second .edit",
                     "domSelector" => %{
                       "xpathNode" => "div > a"
                     }
                   }
                 ]
               }
             ] = screen.smart_object_instances
    end

    test "update smart object class with instance overrides", %{
      public_storyline: storyline,
      screen: screen,
      member: member
    } do
      {:ok, class} = SmartObjects.create_class(simple_class(storyline.id), member)
      class_id = class.id

      SmartObjects.update_instances_in_screen(
        screen.id,
        [
          %{class_id: class_id, edits_overrides: [@second_edit]}
        ],
        member
      )

      {:ok, _} =
        SmartObjects.update_class_and_its_instances(
          class,
          %{
            id: class.id,
            edits: [@second_edit]
          },
          member
        )

      {:ok, classes} = SmartObjects.list_classes(storyline.id)

      assert [
               %{
                 id: ^class_id,
                 edits: [%{"css_selector" => ".second .edit"}]
               }
             ] = classes

      screen = Repo.get!(Api.Storylines.Screen, screen.id)

      assert [
               %{
                 class_id: ^class_id,
                 edits: [
                   @second_edit
                 ],
                 edits_overrides: []
               }
             ] = screen.smart_object_instances
    end

    test "renaming smart object class changes it name", %{
      public_storyline: storyline,
      member: member
    } do
      {:ok, class} = SmartObjects.create_class(simple_class(storyline.id), member)

      class_id = class.id

      assert {:ok, renamed_class} =
               SmartObjects.rename_class(class_id, @update_attrs[:name], member)

      assert renamed_class.name == @update_attrs[:name]
    end

    test "rename smart object class fails with invalid data", %{
      public_storyline: storyline,
      member: member
    } do
      {:ok, class} = SmartObjects.create_class(simple_class(storyline.id), member)

      class_id = class.id

      assert {:error, %Ecto.Changeset{}} =
               SmartObjects.rename_class(class_id, @invalid_attrs[:name], member)
    end

    test "archive smart object class without instance", %{
      public_storyline: storyline,
      member: member
    } do
      {:ok, class} = SmartObjects.create_class(simple_class(storyline.id), member)

      class_id = class.id

      assert {:ok, archived_class} = SmartObjects.archive_class(class_id, member)
      assert String.length(DateTime.to_string(archived_class.archived_at)) > 0
    end

    test "archive smart object class and deletes all instances in screens", %{
      public_storyline: storyline,
      screen: screen,
      member: member
    } do
      {:ok, class} = SmartObjects.create_class(simple_class(storyline.id), member)

      class_id = class.id

      {:ok, _} =
        SmartObjects.update_instances_in_screen(screen.id, [%{class_id: class_id}], member)

      assert {:ok, archived_class} = SmartObjects.archive_class(class_id, member)
      assert [] = screen.smart_object_instances
      assert String.length(DateTime.to_string(archived_class.archived_at)) > 0
    end

    test "should not list archived classes", %{
      public_storyline: storyline,
      member: member
    } do
      {:ok, _class1} = SmartObjects.create_class(simple_class(storyline.id), member)
      {:ok, class2} = SmartObjects.create_class(simple_class(storyline.id), member)

      SmartObjects.archive_class(class2.id, member)

      assert {:ok, classes} = SmartObjects.list_classes(storyline.id)
      assert [_class1] = classes
    end

    test "detaching smart object instance", %{
      public_storyline: storyline,
      screen: screen,
      member: member
    } do
      {:ok, class} = SmartObjects.create_class(simple_class(storyline.id), member)

      class_id = class.id

      {:ok, instances} =
        SmartObjects.update_instances_in_screen(screen.id, [%{class_id: class.id}], member)

      instance = instances |> Enum.at(0)
      {:ok, _} = SmartObjects.detach_instance(screen.id, instance.id, member)

      {:ok, _} =
        SmartObjects.update_class_and_its_instances(
          class,
          %{
            name: "new name",
            thumbnail: "new thumbnail",
            edits: [@second_edit]
          },
          member
        )

      screen = Repo.get!(Api.Storylines.Screen, screen.id)

      assert [
               %{
                 class_id: ^class_id,
                 edits: [
                   %{
                     "css_selector" => ".first .edit",
                     "domSelector" => %{
                       "xpathNode" => "div > a"
                     }
                   }
                 ]
               }
             ] = screen.smart_object_instances
    end
  end

  defp simple_class(storyline_id) do
    %Class{
      storyline_id: storyline_id,
      name: "test smart object",
      thumbnail: "===",
      css_selector: "div > div",
      dom_selector: %{xpath_node: "div > a"},
      edits: [@first_edit]
    }
  end

  defp invalid_class(storyline_id) do
    %Class{
      storyline_id: storyline_id,
      name: "test smart object",
      thumbnail: "===",
      css_selector: "div > div",
      edits: [@invalid_edit]
    }
  end
end
