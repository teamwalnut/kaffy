defmodule Api.StorylinesTest do
  use Api.DataCase, async: true

  alias Api.Annotations
  alias Api.Storylines
  alias Api.Storylines.{Editing, Screen, Storyline}
  alias Api.Storylines.ScreenGrouping.Flow
  alias Api.TestAccess

  describe "storylines" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen
    ]

    @valid_attrs %{name: "some name"}
    @invalid_attrs %{last_edited: nil, name: nil}

    def member_for_company_fixture(company, attrs \\ %{}) do
      user = user_fixture()

      {:ok, member} = Api.Companies.add_member(user.id, company, attrs)
      member
    end

    test "list_all_storylines/0 returns all storylines", %{
      member: member,
      public_storyline: public_storyline
    } do
      member = member |> Api.Repo.preload(:company)
      member2 = member_for_company_fixture(member.company)
      member3 = member_for_company_fixture(member.company)

      public_storyline2 = Api.StorylinesFixtures.public_storyline_fixture(member2, @valid_attrs)
      {:ok, _} = Api.Storylines.add_collaborator(public_storyline2, member.id, member2)
      {:ok, _} = Api.Storylines.add_collaborator(public_storyline2, member3.id, member2)

      private_storyline = Api.StorylinesFixtures.private_storyline_fixture(member, @valid_attrs)

      _private_storyline2 =
        Api.StorylinesFixtures.private_storyline_fixture(member2, @valid_attrs)

      owner = public_storyline |> Api.Repo.preload(:owner) |> Map.get(:owner)

      expected_storylines =
        [
          private_storyline,
          public_storyline2,
          public_storyline
        ]
        |> :sets.from_list()
        |> :sets.to_list()

      actual_storylines =
        Storylines.list_all_storylines(owner.id, owner.company_id)
        |> :sets.from_list()
        |> :sets.to_list()

      assert actual_storylines == expected_storylines
    end

    test "list_all_storylines/0 takes into account collaboration", %{
      member: member,
      public_storyline: public_storyline
    } do
      member = member |> Api.Repo.preload(:company)
      member2 = member_for_company_fixture(member.company)

      private_storyline = Api.StorylinesFixtures.private_storyline_fixture(member2, @valid_attrs)
      {:ok, _} = Storylines.add_collaborator(private_storyline, member.id, member2)

      assert Storylines.list_all_storylines(member.id, member.company_id) == [
               private_storyline,
               public_storyline
             ]
    end

    test "list_private_storylines/0 returns private storylines only", %{member: member} do
      member = member |> Api.Repo.preload(:company)
      member2 = member_for_company_fixture(member.company)

      private_storyline = Api.StorylinesFixtures.private_storyline_fixture(member, @valid_attrs)

      _private_storyline2 =
        Api.StorylinesFixtures.private_storyline_fixture(member2, @valid_attrs)

      _public_storyline = Api.StorylinesFixtures.public_storyline_fixture(member, @valid_attrs)

      assert Storylines.list_private_storylines(member.id, member.company_id) == [
               private_storyline
             ]
    end

    test "list_private_storylines/0 takes collaborators into account", %{member: member} do
      member = member |> Api.Repo.preload(:company)
      member2 = member_for_company_fixture(member.company)

      private_storyline = Api.StorylinesFixtures.private_storyline_fixture(member, @valid_attrs)

      private_storyline2 = Api.StorylinesFixtures.private_storyline_fixture(member2, @valid_attrs)

      {:ok, _} = Storylines.add_collaborator(private_storyline2, member.id, member2)

      _public_storyline = Api.StorylinesFixtures.public_storyline_fixture(member, @valid_attrs)

      assert Storylines.list_private_storylines(member.id, member.company_id) == [
               private_storyline2,
               private_storyline
             ]
    end

    test "list_public_storylines/0 returns public storylines only", %{
      member: member,
      public_storyline: public_storyline
    } do
      member = member |> Api.Repo.preload(:company)
      member2 = member_for_company_fixture(member.company)
      public_storyline2 = Api.StorylinesFixtures.public_storyline_fixture(member2, @valid_attrs)
      _private_storyline2 = Api.StorylinesFixtures.private_storyline_fixture(member, @valid_attrs)

      assert Storylines.list_public_storylines(member.company_id) == [
               public_storyline2,
               public_storyline
             ]
    end

    test "get_storyline!/1 returns the storyline with given id", %{member: member} do
      storyline_fixture = private_storyline_fixture(member, @valid_attrs)
      assert Storylines.get_storyline!(storyline_fixture.id) == storyline_fixture
    end

    test "update_storyline/2 with valid name updates the storyline", %{
      public_storyline: storyline,
      member: member
    } do
      assert {:ok, %Storyline{} = updated_storyline} =
               Storylines.update_storyline(storyline, %{name: "#{storyline.name}11"}, member)

      assert updated_storyline.name == "#{storyline.name}11"
    end

    test "create_public_storyline/1 with valid data creates a storyline", %{
      public_storyline: storyline
    } do
      assert DateTime.diff(~U[2010-04-17T14:00:00Z], storyline.last_edited, :second) < 15
      assert storyline.name =~ "storyline_"
      assert storyline.is_public == true
    end

    test "create_public_storyline/1 with invalid data returns error changeset", %{
      member: member
    } do
      assert {:error, %Ecto.Changeset{}} =
               Storylines.create_public_storyline(@invalid_attrs, member)
    end

    test "create_public_storyline/1 with valid data creates a storyline with settings", %{
      public_storyline: storyline
    } do
      assert storyline.settings != nil
    end

    test "create_public_storyline/1 implements correct authorization", %{member: member} do
      Api.TestAccess.assert_roles(
        &Storylines.create_public_storyline(%{name: "A title"}, &1),
        member,
        %TestAccess{viewer: false, presenter: false, editor: true, company_admin: true}
      )
    end

    test "create_private_storyline/1 with valid data creates a storyline", %{member: member} do
      assert {:ok, %Storyline{} = storyline} =
               Storylines.create_private_storyline(@valid_attrs, member)

      assert DateTime.diff(DateTime.utc_now(), storyline.last_edited, :second) < 15
      assert storyline.name == "some name"
      assert storyline.is_public == false
    end

    test "create_private_storyline/1 with no data creates a storyline with default name", %{
      member: member
    } do
      assert {:ok, %Storyline{} = storyline} = Storylines.create_private_storyline(%{}, member)

      assert DateTime.diff(DateTime.utc_now(), storyline.last_edited, :second) < 15
      assert storyline.name == "New Storyline"
      assert storyline.is_public == false
    end

    test "create_private_storyline/1 with no data twice generate consecutive names", %{
      member: member
    } do
      assert {:ok, %Storyline{} = storyline} = Storylines.create_private_storyline(%{}, member)
      assert {:ok, %Storyline{} = storyline2} = Storylines.create_private_storyline(%{}, member)

      assert storyline.name == "New Storyline"
      assert storyline2.name == "New Storyline 2"
    end

    test "create_private_storyline/1 with no data when there is 'New Storyline 1' storyline still generates consecutive name",
         %{
           member: member
         } do
      assert {:ok, %Storyline{} = storyline} =
               Storylines.create_private_storyline(%{name: "New Storyline 1"}, member)

      assert {:ok, %Storyline{} = storyline2} = Storylines.create_private_storyline(%{}, member)

      assert storyline.name == "New Storyline 1"
      assert storyline2.name == "New Storyline 2"
    end

    test "create_private_storyline/1 with no data when there is previous storyline default name generates consecutive default name",
         %{
           member: member
         } do
      assert {:ok, %Storyline{} = storyline} =
               Storylines.create_private_storyline(%{name: "New Storyline 13"}, member)

      assert {:ok, %Storyline{} = storyline2} = Storylines.create_private_storyline(%{}, member)

      assert storyline.name == "New Storyline 13"
      assert storyline2.name == "New Storyline 14"
    end

    test "create_private_storyline/1 with no data when there are no previous default names generates the default name",
         %{
           member: member
         } do
      assert {:ok, %Storyline{} = storyline} =
               Storylines.create_private_storyline(%{name: "New Storyline Test13"}, member)

      assert {:ok, %Storyline{} = storyline2} = Storylines.create_private_storyline(%{}, member)

      assert storyline.name == "New Storyline Test13"
      assert storyline2.name == "New Storyline"
    end

    test "create_private_storyline/1 with valid data creates a storyline with settings", %{
      member: member
    } do
      assert {:ok, %Storyline{} = storyline} =
               Storylines.create_private_storyline(@valid_attrs, member)

      assert storyline.settings != nil
    end

    test "delete_storyline/1 deletes the storyline", %{public_storyline: storyline} do
      assert {:ok, %Storyline{}} = Storylines.delete_storyline(storyline)
      assert_raise Ecto.NoResultsError, fn -> Storylines.get_storyline!(storyline.id) end
    end

    test "update_storyline/2 can update the start_screen", %{
      public_storyline: storyline,
      member: member
    } do
      screen = Api.StorylinesFixtures.screen_fixture(storyline)

      assert {:ok, %Storyline{} = _updated_storyline} =
               Storylines.update_storyline(storyline, %{start_screen_id: screen.id}, member)

      updated_storyline = Storylines.get_storyline!(storyline.id)
      assert updated_storyline.start_screen_id == screen.id
    end
  end

  describe "screens" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline
    ]

    @valid_attrs %{
      screenshot_image_uri: "some image_uri",
      last_edited: "2010-04-17T14:00:00Z",
      name: "some name",
      url: "some url",
      s3_object_name: "some_object_name"
    }
    @update_attrs %{
      screenshot_image_uri: "some updated image_uri",
      last_edited: "2011-05-18T15:01:01Z",
      name: "some updated name",
      url: "some updated url",
      s3_object_name: "some_object_name"
    }
    @invalid_attrs %{screenshot_image_uri: nil, last_edited: nil, name: nil, url: nil}

    test "list_screens/0 returns all screens", %{public_storyline: storyline, member: member} do
      screen = Api.StorylinesFixtures.screen_fixture(storyline)
      storyline2 = Api.StorylinesFixtures.public_storyline_fixture(member)
      screen2 = Api.StorylinesFixtures.screen_fixture(storyline2)
      assert Storylines.list_screens(storyline) == [screen]
      assert Storylines.list_screens(storyline2) == [screen2]
    end

    test "get_screen!/1 returns the screen with given id", %{public_storyline: storyline} do
      screen = Api.StorylinesFixtures.screen_fixture(storyline)
      assert Storylines.get_screen!(screen.id) == screen
    end

    test "get_screen/1 returns the screen with given id", %{
      public_storyline: storyline,
      member: member
    } do
      screen = Api.StorylinesFixtures.screen_fixture(storyline)
      screen_id = screen.id
      assert {:ok, %Screen{id: ^screen_id}} = Storylines.fetch_screen(screen.id, member)
    end

    test "add_screen_to_default_flow/2 with valid data creates a screen", %{
      public_storyline: storyline,
      member: member
    } do
      current_datetime = DateTime.utc_now()

      assert {:ok, %Screen{} = screen} =
               Storylines.add_screen_to_default_flow(storyline, member, @valid_attrs)

      assert screen.screenshot_image_uri == "some image_uri"
      refute is_nil(screen.last_edited)
      assert screen.name == "some name"
      assert screen.url == "some url"

      updated_storyline = Storylines.get_storyline!(storyline.id)
      assert DateTime.compare(updated_storyline.last_edited, current_datetime) == :gt
    end

    test "add_screen_to_default_flow/2 can optionally accept width/height", %{
      public_storyline: storyline,
      member: member
    } do
      attrs = @valid_attrs |> Map.merge(%{original_dimensions: %{height: 10, width: 22}})

      assert {:ok, %Screen{} = screen} =
               Storylines.add_screen_to_default_flow(storyline, member, attrs)

      assert screen.screenshot_image_uri == "some image_uri"
      refute is_nil(screen.last_edited)
      assert screen.name == "some name"
      assert screen.url == "some url"

      assert screen.original_dimensions == %Screen.Dimensions{
               height: 10,
               width: 22
             }
    end

    test "add_screen_to_default_flow/2 for the first screen also marks it as start_screen on the storyline",
         %{public_storyline: storyline, member: member} do
      assert {:ok, %Screen{} = screen} =
               Storylines.add_screen_to_default_flow(storyline, member, @valid_attrs)

      assert {:ok, %Screen{} = _screen2} =
               Storylines.add_screen_to_default_flow(storyline, member, @valid_attrs)

      storyline =
        Api.Repo.get(Api.Storylines.Storyline, storyline.id) |> Api.Repo.preload(:start_screen)

      assert storyline.start_screen == screen
    end

    test "add_screen_to_default_flow/2 with invalid data returns error changeset", %{
      public_storyline: storyline,
      member: member
    } do
      assert {:error, :screen, %Ecto.Changeset{}, _} =
               Storylines.add_screen_to_default_flow(storyline, member, @invalid_attrs)
    end

    test "update_screen/2 with valid data updates the screen", %{
      public_storyline: storyline,
      member: member
    } do
      screen = Api.StorylinesFixtures.screen_fixture(storyline)
      assert {:ok, %Screen{} = screen} = Storylines.update_screen(screen, @update_attrs, member)
      refute is_nil(screen.last_edited)
      assert screen.name == "some updated name"
      assert screen.url == "some updated url"
    end

    test "update_screen/2 with invalid data returns error changeset", %{
      public_storyline: storyline,
      member: member
    } do
      screen = Api.StorylinesFixtures.screen_fixture(storyline)

      assert {:error, %Ecto.Changeset{}} =
               Storylines.update_screen(screen, @invalid_attrs, member)

      assert screen == Storylines.get_screen!(screen.id)
    end

    test "change_screen/1 returns a screen changeset", %{public_storyline: storyline} do
      screen = Api.StorylinesFixtures.screen_fixture(storyline)
      assert %Ecto.Changeset{} = Storylines.change_screen(screen)
    end

    test "unlinked_screen_ids/1 returns correctly the unlinked screens", %{
      public_storyline: storyline,
      member: member
    } do
      screen1 = Api.StorylinesFixtures.screen_fixture(storyline)
      screen2 = Api.StorylinesFixtures.screen_fixture(storyline)
      screen3 = Api.StorylinesFixtures.screen_fixture(storyline)
      screen4 = Api.StorylinesFixtures.screen_fixture(storyline)

      Editing.add_edit(screen1.id, %{
        kind: :link,
        css_selector: "first",
        dom_selector: nil,
        link_edit_props: %{destination: %{kind: "screen", id: screen2.id}},
        last_edited_at: DateTime.utc_now()
      })

      {:ok, guide} = Annotations.create_guide(storyline.id, %{name: "Guide 2"}, member)

      Annotations.add_annotation_to_guide(
        guide.id,
        %{
          kind: :modal,
          message: "annotation 1",
          rich_text: %{
            "delta" => %{"ops" => [%{"insert" => "annotation 1"}, %{"insert" => "\n"}]},
            "version" => "QuillDelta_20211027"
          },
          last_edited: "2010-04-17T14:00:00Z",
          screen_id: screen3.id
        },
        :modal,
        member
      )

      Annotations.add_annotation_to_guide(
        guide.id,
        %{
          kind: :modal,
          message: "annotation 2",
          rich_text: %{
            "delta" => %{"ops" => [%{"insert" => "annotation 2"}, %{"insert" => "\n"}]},
            "version" => "QuillDelta_20211027"
          },
          last_edited: "2010-04-17T14:00:00Z",
          screen_id: screen4.id
        },
        :modal,
        member
      )

      assert Storylines.unlinked_screen_ids(storyline.id) == MapSet.new([screen1.id, screen3.id])
    end
  end

  describe "collaborators" do
    alias Api.Storylines.Collaborator

    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen,
      :setup_collaborator
    ]

    test "list_collaborators/1 returns all collaborators", %{
      public_storyline: storyline,
      collaborator: collab
    } do
      assert Storylines.list_collaborators(storyline) == [collab]
    end

    test "add_collaborator/2 with valid data creates a collaborator", %{
      public_storyline: storyline,
      company: company
    } do
      user = user_fixture()
      {:ok, member} = Api.Companies.add_member(user.id, company)

      assert {:ok, %Collaborator{} = _collaborator} =
               Storylines.add_collaborator(storyline, member.id, member)
    end

    test "add_collaborator/2 when it already exists should fail", %{
      public_storyline: storyline,
      member: member
    } do
      assert {:error, %Ecto.Changeset{}} =
               Storylines.add_collaborator(storyline, member.id, member)
    end

    test "add_collaborator/2 when adding owner should fail", %{
      public_storyline: storyline
    } do
      storyline = storyline |> Api.Repo.preload(:owner)

      assert {:error, %Ecto.Changeset{} = _changeset} =
               Storylines.add_collaborator(storyline, storyline.owner.id, storyline.owner)
    end

    test "remove_collaborator/2 removes the collaborator", %{
      public_storyline: storyline,
      collaborator: collaborator,
      member: member
    } do
      collaborator = collaborator |> Api.Repo.preload(:member)
      assert :ok = Storylines.remove_collaborator(storyline, collaborator.member.id, member)
      assert Storylines.is_collaborator(storyline, collaborator.member.id) == false
    end

    test "update_start_screen/2 with with valid data updates the demo", %{
      public_storyline: storyline,
      member: member
    } do
      screen = screen_fixture(storyline)
      %{demo: demo} = storyline |> demo_fixture(member)

      assert {:ok, updated_screen_demo} = Storylines.update_start_screen(demo, screen.id)
      assert updated_screen_demo.start_screen_id == screen.id
    end

    test "update_start_screen/2 with valid data updates the storyline", %{
      public_storyline: storyline
    } do
      screen = screen_fixture(storyline)

      assert {:ok, updated_screen_storyline} =
               Storylines.update_start_screen(storyline, screen.id)

      assert updated_screen_storyline.start_screen_id == screen.id
    end

    test "copy_flow/2 copy default flow to storyline that already has default flow will fail", %{
      public_storyline: storyline,
      member: member
    } do
      default_flow = storyline |> Api.Repo.preload(:flows) |> Map.get(:flows) |> Enum.at(0)
      another_storyline = Api.StorylinesFixtures.public_storyline_fixture(member, @valid_attrs)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Storylines.copy_flow(another_storyline, default_flow)

      assert changeset.errors |> Enum.count() == 1
    end

    test "copy_flow/2 copies default flow for demo version", %{
      public_storyline: storyline,
      member: member
    } do
      default_flow = storyline |> Api.Repo.preload(:flows) |> Map.get(:flows) |> Enum.at(0)
      %{demo: demo, active_demo_version: demo_version} = storyline |> demo_fixture(member)

      assert {:ok, %Flow{}} = Storylines.copy_flow(demo, default_flow)
      demo_flows = Flow.list_demo_query(demo.id) |> Repo.all()

      assert demo_flows |> Enum.count() == 1
      assert demo_flows |> Enum.at(0) |> Map.get(:demo_version_id) == demo_version.id
      assert demo_flows |> Enum.at(0) |> Map.get(:name) == "Default"
      assert demo_flows |> Enum.at(0) |> Map.get(:is_default) == true
    end

    test "copy_flow/2 copies non default flow for demo", %{
      public_storyline: storyline,
      member: member
    } do
      flow = flow_fixture(storyline.id)
      %{demo: demo, active_demo_version: demo_version} = storyline |> demo_fixture(member)

      assert {:ok, %Flow{}} = Storylines.copy_flow(demo, flow)
      demo_flows = Flow.list_demo_query(demo.id) |> Repo.all()

      assert demo_flows |> Enum.count() == 1
      assert demo_flows |> Enum.at(0) |> Map.get(:demo_version_id) == demo_version.id
      assert demo_flows |> Enum.at(0) |> Map.get(:is_default) == false
      assert demo_flows |> Enum.at(0) |> Map.get(:name) == flow.name
    end
  end
end
