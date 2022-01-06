defmodule ApiWeb.GraphQL.CopyStorylineTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines.Editing
  alias Api.TestAccess

  load_gql(
    :copy_storyline,
    ApiWeb.Schema,
    "test/support/mutations/CopyStoryline.gql"
  )

  load_gql(
    :list_smart_object_classes,
    ApiWeb.Schema,
    "test/support/queries/SmartObjectClasses.gql"
  )

  load_gql(
    :add_smart_object_class,
    ApiWeb.Schema,
    "test/support/mutations/AddSmartObjectClass.gql"
  )

  load_gql(
    :add_instances_to_screen,
    ApiWeb.Schema,
    "test/support/mutations/UpdateSmartObjectInstancesInScreen.gql"
  )

  setup [:register_and_log_in_member]

  describe "copyStoryline" do
    test "it should copy the storyline correctly", %{context: context} do
      public_storyline = Api.StorylinesFixtures.public_storyline_fixture(context.current_member)

      screen1 = Api.StorylinesFixtures.screen_fixture(public_storyline)
      screen2 = Api.StorylinesFixtures.screen_fixture(public_storyline)

      Editing.add_edit(screen1.id, %{
        kind: :link,
        css_selector: "first",
        dom_selector: nil,
        last_edited_at: DateTime.utc_now(),
        link_edit_props: %{destination: %{kind: "screen", id: screen2.id}}
      })

      Editing.add_edit(screen1.id, %{
        kind: :link,
        css_selector: "second",
        dom_selector: nil,
        last_edited_at: DateTime.utc_now(),
        link_edit_props: %{destination: %{kind: "screen", id: screen2.id}}
      })

      Editing.add_edit(screen2.id, %{
        kind: :link,
        css_selector: "some css",
        dom_selector: nil,
        last_edited_at: DateTime.utc_now(),
        link_edit_props: %{destination: %{kind: "screen", id: screen1.id}}
      })

      result =
        query(
          :copy_storyline,
          %{"storylineId" => public_storyline.id},
          context
        )
        |> get_in(["copyStoryline"])

      assert result |> Map.get("id") != public_storyline.id
      assert result |> Map.get("name") == "Copy of #{public_storyline.name}"

      screen1 =
        result
        |> Map.get("screens")
        |> Enum.find(fn screen -> screen["name"] == screen1.name end)

      edits = screen1 |> Map.get("edits")
      edit1 = edits |> Enum.at(0)
      edit2 = edits |> Enum.at(1)

      assert edit1["cssSelector"] == "first"
      assert edit2["cssSelector"] == "second"
    end

    test "authorization", %{context: context} do
      public_storyline = Api.StorylinesFixtures.public_storyline_fixture(context.current_member)

      TestAccess.assert_roles(
        &query_gql_by(
          :copy_storyline,
          variables: %{"storylineId" => public_storyline.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end

    test "it should fail when trying to change owners and current user isn't an admin", %{
      context: context
    } do
      different_user = Api.AccountsFixtures.user_fixture()

      %{member: different_member} =
        Api.CompaniesFixtures.company_and_member_fixture(different_user)

      public_storyline = Api.StorylinesFixtures.public_storyline_fixture(context.current_member)

      assert {:ok, query_data} =
               query_gql_by(:copy_storyline,
                 variables: %{
                   "storylineId" => public_storyline.id,
                   "targetOwnerId" => different_member.id
                 },
                 context: context
               )

      assert unauthorized_error(query_data)
    end

    test "it should copy the storyline correctly while changing owners if the current user is an admin",
         %{context: context} do
      user = Api.Accounts.make_admin!(context.current_user)
      member = %{context.current_member | user: user}

      context =
        context
        |> Map.put(:current_user, user)
        |> Map.put(:current_member, member)

      %{member: different_member} =
        Api.AccountsFixtures.user_fixture() |> Api.CompaniesFixtures.company_and_member_fixture()

      public_storyline = Api.StorylinesFixtures.public_storyline_fixture(context.current_member)

      assert {:ok, query_data} =
               query_gql_by(:copy_storyline,
                 variables: %{
                   "storylineId" => public_storyline.id,
                   "targetOwnerId" => different_member.id
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "copyStoryline"])

      assert result |> Map.get("id") != public_storyline.id
      assert result |> Map.get("owner") |> Map.get("id") == different_member.id
      assert result |> Map.get("name") == "Copy of #{public_storyline.name}"
    end

    test "it should copy storyline smart object classes correctly", %{
      context: context
    } do
      storyline = Api.StorylinesFixtures.public_storyline_fixture(context.current_member)

      query(
        :add_smart_object_class,
        %{
          "storylineId" => storyline.id,
          "smartObjectClass" => smart_object_class_for_gql_fixture()
        },
        context
      )

      _origin_classes =
        query(
          :list_smart_object_classes,
          %{"storylineId" => storyline.id},
          context
        )
        |> get_in(["storyline", "smartObjectClasses"])

      copied_storyline_id =
        query(
          :copy_storyline,
          %{"storylineId" => storyline.id},
          context
        )
        |> get_in(["copyStoryline", "id"])

      copied_classes =
        query(
          :list_smart_object_classes,
          %{"storylineId" => copied_storyline_id},
          context
        )
        |> get_in(["storyline", "smartObjectClasses"])

      # assert classes storyline association was successfully remapped during copying
      copied_classes
      |> Enum.each(fn class -> assert class["storylineId"] == copied_storyline_id end)
    end
  end

  defp query(query, variables, context) do
    assert {:ok, query_data} = query_gql_by(query, variables: variables, context: context)
    no_errors!(query_data)
    get_in(query_data, [:data])
  end
end
