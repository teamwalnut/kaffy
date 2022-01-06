defmodule ApiWeb.GraphQL.SmartObjectsTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :add_edits,
    ApiWeb.Schema,
    "test/support/mutations/AddEdits.gql"
  )

  load_gql(
    :list_smart_object_classes,
    ApiWeb.Schema,
    "test/support/queries/SmartObjectClasses.gql"
  )

  load_gql(
    :add_edits_smart_object_class,
    ApiWeb.Schema,
    "test/support/mutations/AddEditsSmartObjectsClass.gql"
  )

  load_gql(
    :add_smart_object_class,
    ApiWeb.Schema,
    "test/support/mutations/AddSmartObjectClass.gql"
  )

  load_gql(
    :rename_smart_object_class,
    ApiWeb.Schema,
    "test/support/mutations/RenameSmartObjectClass.gql"
  )

  load_gql(
    :archive_smart_object_class,
    ApiWeb.Schema,
    "test/support/mutations/ArchiveSmartObjectClass.gql"
  )

  load_gql(
    :get_screen,
    ApiWeb.Schema,
    "test/support/queries/GetSmartObjectInstancesFromScreen.gql"
  )

  load_gql(
    :update_smart_object_instances_in_screen,
    ApiWeb.Schema,
    "test/support/mutations/UpdateSmartObjectInstancesInScreen.gql"
  )

  load_gql(
    :update_class,
    ApiWeb.Schema,
    "test/support/mutations/UpdateSmartObjectClass.gql"
  )

  load_gql(
    :detach_instance,
    ApiWeb.Schema,
    "test/support/mutations/DetachSmartObjectInstance.gql"
  )

  @smart_object_rename "SO rename"

  describe "smart objects classes" do
    setup [
      :register_and_log_in_member,
      :setup_public_storyline,
      :setup_screen
    ]

    test "new storyline has no smart objects classes", %{
      public_storyline: public_storyline,
      context: context
    } do
      classes =
        query(:list_smart_object_classes, %{"storylineId" => public_storyline.id}, context)
        |> get_in(["storyline", "smartObjectClasses"])

      assert classes == []
    end

    test "add smart object class", %{public_storyline: storyline, context: context} do
      query_gql_by(
        :add_smart_object_class,
        variables: %{
          "storylineId" => storyline.id,
          "smartObjectClass" => smart_object_class_for_gql_fixture()
        },
        context: context
      )
      |> match_snapshot(scrub: ["id"])
    end

    test "authorize add smart object class", %{public_storyline: storyline, context: context} do
      TestAccess.assert_roles(
        &query_gql_by(
          :add_smart_object_class,
          variables: %{
            "storylineId" => storyline.id,
            "smartObjectClass" => smart_object_class_for_gql_fixture()
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "create and retrieve smart object classes in storyline", %{
      public_storyline: storyline,
      context: context
    } do
      query(
        :add_smart_object_class,
        %{
          "storylineId" => storyline.id,
          "smartObjectClass" => %{
            "name" => "my smart object class",
            "thumbnail" => smart_object_class_thumbnail_fixture(),
            "edits" => [
              smart_object_style_edit_fixture(),
              smart_object_text_edit_fixture(),
              smart_object_binding_edit_fixutre()
            ],
            "domSelector" => %{
              "xpathNode" => "div > a",
              "xpathFrames" => ["xpath iframe"]
            },
            "frameSelectors" => ["iframe"],
            "cssSelector" => "body"
          }
        },
        context
      )

      results =
        query(
          :list_smart_object_classes,
          %{"storylineId" => storyline.id},
          context
        )
        |> get_in(["storyline", "smartObjectClasses"])

      assert [
               %{
                 "domSelector" => %{
                   "xpathNode" => "div > a",
                   "xpathFrames" => ["xpath iframe"]
                 },
                 "cssSelector" => "body",
                 "frameSelectors" => ["iframe"],
                 "edits" => [
                   %{"kind" => "STYLE"},
                   %{"kind" => "TEXT"},
                   %{"kind" => "BINDING"}
                 ],
                 "id" => _,
                 "name" => "my smart object class",
                 "thumbnail" => _
               }
             ] = results
    end

    test "class edits accountable to edits structure", %{
      public_storyline: storyline,
      context: context
    } do
      screen =
        storyline
        |> Api.StorylinesFixtures.screen_fixture()

      query(
        :add_edits_smart_object_class,
        %{"storylineId" => storyline.id, "screenId" => screen.id},
        context
      )

      {:ok, so_edits_results} =
        query(
          :list_smart_object_classes,
          %{"storylineId" => storyline.id},
          context
        )
        |> get_in(["storyline", "smartObjectClasses"])
        |> List.first()
        |> Map.fetch("edits")

      so_edits_results |> match_snapshot(scrub: ["id", "lastEditedAt"])

      query(
        :add_edits,
        %{"screenId" => screen.id},
        context
      )
      |> get_in(["addEditsToScreen"])
      |> match_snapshot(scrub: ["id", "lastEditedAt"])
    end

    test "instance edits accountable to edits structure", %{
      public_storyline: storyline,
      context: context
    } do
      screen =
        storyline
        |> Api.StorylinesFixtures.screen_fixture()

      class_id =
        query(
          :add_edits_smart_object_class,
          %{"storylineId" => storyline.id, "screenId" => screen.id},
          context
        )
        |> get_in(["addSmartObjectClass", "id"])

      query(
        :update_smart_object_instances_in_screen,
        %{
          "screenId" => screen.id,
          "instances" => [%{"classId" => class_id}]
        },
        context
      )

      instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      {:ok, instance_edits_results} = instances |> List.first() |> Map.fetch("edits")

      instance_edits_results |> match_snapshot(scrub: ["id", "lastEditedAt"])

      query(
        :add_edits,
        %{"screenId" => screen.id},
        context
      )
      |> get_in(["addEditsToScreen"])
      |> match_snapshot(scrub: ["id", "storylineId", "lastEditedAt"])
    end

    test "should return error when creating smart object class with empty edit css selector", %{
      public_storyline: storyline,
      context: context
    } do
      try do
        query(
          :add_smart_object_class,
          %{
            "storylineId" => storyline.id,
            "smartObjectClass" => smart_object_class_empty_edit_selector()
          },
          context
        )
      catch
        error ->
          assert [%{path: ["addSmartObjectClass"], status_code: 500}] = error
      end
    end

    test "create an instance from a class", %{
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

      instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      assert [
               %{
                 "classId" => ^class_id,
                 "cssSelector" => "body",
                 "frameSelectors" => ["iframe"],
                 "domSelector" => %{
                   "xpathNode" => "div > a",
                   "xpathFrames" => ["xpath iframe"]
                 },
                 "edits" => [
                   %{"kind" => "STYLE"},
                   %{"kind" => "TEXT"}
                 ]
               }
             ] = instances
    end

    test "updateSmartObjectInstancesInScreen", %{
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

      query_gql_by(
        :update_smart_object_instances_in_screen,
        variables: %{"screenId" => screen.id, "instances" => [%{"classId" => class_id}]},
        context: context
      )
      |> match_snapshot(scrub: ["id", "classId"])
    end

    test "authorize updateSmartObjectInstancesInScreen", %{
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

      TestAccess.assert_roles(
        &query_gql_by(
          :update_smart_object_instances_in_screen,
          variables: %{"screenId" => screen.id, "instances" => [%{"classId" => class_id}]},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "create an instance with edits overrides from a class", %{
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
        %{
          "screenId" => screen.id,
          "instances" => [
            %{"classId" => class_id, "editsOverrides" => [smart_object_style_edit_fixture()]}
          ]
        },
        context
      )

      instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      assert [
               %{
                 "classId" => ^class_id,
                 "cssSelector" => "body",
                 "edits" => [
                   %{"kind" => "STYLE"},
                   %{"kind" => "TEXT"}
                 ],
                 "frameSelectors" => ["iframe"],
                 "editsOverrides" => [%{"kind" => "STYLE"}]
               }
             ] = instances
    end

    test "updating a class should update it and its instances", %{
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

      query(
        :update_class,
        %{
          "smartObjectClassId" => class_id,
          "edits" => [smart_object_text_edit_fixture()],
          "name" => "new name",
          "thumbnail" => "aW1hZ2UK"
        },
        context
      )

      updated_class =
        query(:list_smart_object_classes, %{"storylineId" => storyline.id}, context)
        |> get_in(["storyline", "smartObjectClasses"])

      # assert the class was updated
      assert [
               %{
                 "name" => "new name",
                 "thumbnail" => "aW1hZ2UK",
                 "edits" => [
                   %{"kind" => "TEXT"}
                 ]
               }
             ] = updated_class

      # assert all of the class' instances were updated
      updated_instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      assert [
               %{
                 "classId" => ^class_id,
                 "edits" => [%{"kind" => "TEXT"}]
               }
             ] = updated_instances
    end

    test "should be able to update a class", %{public_storyline: storyline, context: context} do
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
        :update_class,
        %{
          "smartObjectClassId" => class_id,
          "edits" => [smart_object_text_edit_fixture()],
          "name" => "new name",
          "thumbnail" => "aW1hZ2UK"
        },
        context
      )
      |> match_snapshot(scrub: ["id"])
    end

    test "authorize update class", %{public_storyline: storyline, context: context} do
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

      TestAccess.assert_roles(
        &query_gql_by(
          :update_class,
          variables: %{
            "smartObjectClassId" => class_id,
            "edits" => [smart_object_text_edit_fixture()],
            "name" => "new name",
            "thumbnail" => "aW1hZ2UK"
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "should be able to archive a class", %{
      public_storyline: storyline,
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

      archived_id =
        query(:archive_smart_object_class, %{"smartObjectClass" => class_id}, context)
        |> get_in(["archiveSmartObjectClass", "id"])

      assert ^class_id = archived_id
    end

    test "authorize archiving of a class", %{
      public_storyline: storyline,
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

      TestAccess.assert_roles(
        &query_gql_by(
          :archive_smart_object_class,
          variables: %{"smartObjectClass" => class_id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "should be able to rename a class", %{
      public_storyline: storyline,
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

      updated_class =
        query(
          :rename_smart_object_class,
          %{"smartObjectClassId" => class_id, "name" => @smart_object_rename},
          context
        )
        |> get_in(["renameSmartObjectClass"])

      assert %{
               "id" => ^class_id,
               "name" => @smart_object_rename
             } = updated_class
    end

    test "authorize class rename", %{public_storyline: storyline, context: context} do
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

      TestAccess.assert_roles(
        &query_gql_by(
          :rename_smart_object_class,
          variables: %{"smartObjectClassId" => class_id, "name" => @smart_object_rename},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "should be able to override an instance's data and it should not be updateable by the class",
         %{
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
        %{
          "screenId" => screen.id,
          "instances" => [
            %{
              "classId" => class_id,
              "overrideDomSelector" => %{
                "xpathNode" => "div > a",
                "xpathFrames" => ["xpath iframe"]
              },
              "overrideCssSelector" => ".ovr .selector",
              "overrideFrameSelectors" => ["parent", "overridden"]
            }
          ]
        },
        context
      )

      instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      assert [
               %{
                 "classId" => ^class_id,
                 "cssSelector" => ".ovr .selector",
                 "frameSelectors" => ["parent", "overridden"]
               }
             ] = instances

      query(
        :update_class,
        %{
          "smartObjectClassId" => class_id,
          "edits" => [smart_object_text_edit_fixture()],
          "name" => "new name",
          "thumbnail" => "aW1hZ2UK"
        },
        context
      )

      # assert the instances overridden values should not change
      instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      assert [
               %{
                 "classId" => ^class_id,
                 "cssSelector" => ".ovr .selector",
                 "frameSelectors" => ["parent", "overridden"]
               }
             ] = instances
    end

    test "should be able to detach an instance",
         %{
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

      instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      assert [
               %{
                 "id" => instance_id,
                 "classId" => ^class_id,
                 "detached" => false,
                 "edits" => [
                   %{"kind" => "STYLE"},
                   %{"kind" => "TEXT"}
                 ]
               }
             ] = instances

      query(
        :detach_instance,
        %{"screenId" => screen.id, "instanceId" => instance_id},
        context
      )

      query(
        :update_class,
        %{"smartObjectClassId" => class_id, "edits" => smart_object_text_edit_fixture()},
        context
      )

      instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      assert [
               %{
                 "classId" => ^class_id,
                 "detached" => true,
                 "edits" => [
                   %{"kind" => "STYLE"},
                   %{"kind" => "TEXT"}
                 ]
               }
             ] = instances
    end

    test "authorize detach instance", %{
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

      instances =
        query(:get_screen, %{"storylineId" => storyline.id, "screenId" => screen.id}, context)
        |> get_in(["screen", "smartObjectInstances"])

      assert [%{"id" => instance_id}] = instances

      TestAccess.assert_roles(
        fn member ->
          query_gql_by(
            :detach_instance,
            variables: %{"screenId" => screen.id, "instanceId" => instance_id},
            context: Map.put(context, :current_member, member)
          )
        end,
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
