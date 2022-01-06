defmodule Api.DemosTest do
  use Api.DataCase, async: true
  alias Api.Settings.StorylineSettings
  alias Api.Storylines.Demos.Demo

  alias Api.Demos

  describe "demos" do
    alias Api.Storylines.Archived
    alias Api.Storylines.Demos
    alias Api.Storylines.Demos.Archive
    alias Api.Storylines.Demos.DemoVersion
    alias Api.Storylines.Editing

    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_multiple_screens,
      :setup_guide,
      :get_default_flow
    ]

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    test "list_all_demos/1 returns all demos per company", %{
      public_storyline: public_storyline,
      company: company,
      member: member
    } do
      another_storyline = public_storyline_fixture(member)
      screen_fixture(another_storyline)

      another_storyline = another_storyline |> Api.Repo.reload()

      assert {:ok, %{demo: demo}} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:ok, %{demo: demo_for_different_storyline}} =
               Demos.create_demo(another_storyline.id, @valid_attrs, member)

      returned_demos = Demos.list_all_demos(company.id, member.id)
      assert returned_demos === [demo_for_different_storyline, demo]
    end

    test "list_all_demos/1 doesn't return demos where their storyline is archived", %{
      public_storyline: public_storyline,
      company: company,
      member: member
    } do
      another_storyline = public_storyline_fixture(member)
      screen_fixture(another_storyline)
      Archived.archive(another_storyline, member)

      another_storyline = another_storyline |> Api.Repo.reload()

      assert {:ok, %{demo: demo}} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:ok, %{demo: _demo_for_different_storyline}} =
               Demos.create_demo(another_storyline.id, @valid_attrs, member)

      returned_demos = Demos.list_all_demos(company.id, member.id)
      assert returned_demos === [demo]
    end

    test "list_all_demos/1 doesn't return is_shared=true demo if storyline is private", %{
      public_storyline: public_storyline,
      company: company,
      member: member
    } do
      another_user = Api.AccountsFixtures.user_fixture()

      {:ok, another_member} =
        Api.Companies.add_member(another_user.id, company, %{role: :company_admin})

      another_storyline = private_storyline_fixture(another_member)
      screen_fixture(another_storyline)

      another_storyline = another_storyline |> Api.Repo.reload()

      assert {:ok, %{demo: demo}} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:ok, %{demo: _demo_for_different_storyline}} =
               Demos.create_demo(
                 another_storyline.id,
                 @valid_attrs |> Map.merge(%{is_shared: true}),
                 another_member
               )

      returned_demos = Demos.list_all_demos(company.id, member.id)
      assert returned_demos === [demo]
    end

    test "list_all_demos/1 doesnt return demos of another company and unshared demos", %{
      public_storyline: public_storyline,
      company: company,
      member: member
    } do
      another_user = Api.AccountsFixtures.user_fixture()
      another_company = Api.CompaniesFixtures.company_fixture()

      {:ok, another_member} =
        Api.Companies.add_member(another_user.id, another_company, %{role: :company_admin})

      another_storyline = private_storyline_fixture(another_member)
      screen_fixture(another_storyline)

      another_storyline = another_storyline |> Api.Repo.reload()

      assert {:ok, %{demo: demo}} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:ok, %{demo: demo_of_another_member}} =
               Demos.create_demo(
                 another_storyline.id,
                 @valid_attrs |> Map.merge(%{is_shared: false}),
                 another_member
               )

      returned_demos = Demos.list_all_demos(company.id, member.id)

      assert returned_demos === [demo]
      refute demo_of_another_member in returned_demos
    end

    test "list_all_demos/1 don't return shared demos from another company", %{
      public_storyline: public_storyline,
      company: company,
      member: member
    } do
      another_user = Api.AccountsFixtures.user_fixture()
      another_company = Api.CompaniesFixtures.company_fixture()

      {:ok, another_member} =
        Api.Companies.add_member(another_user.id, another_company, %{role: :company_admin})

      another_storyline = private_storyline_fixture(another_member)
      screen_fixture(another_storyline)

      another_storyline = another_storyline |> Api.Repo.reload()

      assert {:ok, %{demo: demo}} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:ok, %{demo: _demo_of_another_member}} =
               Demos.create_demo(
                 another_storyline.id,
                 @valid_attrs |> Map.merge(%{is_shared: true}),
                 another_member
               )

      returned_demos = Demos.list_all_demos(company.id, member.id)

      assert returned_demos === [demo]
    end

    test "list_all_demos/1 return demos where the member is a collborator", %{
      public_storyline: public_storyline,
      company: company,
      member: member
    } do
      another_user = Api.AccountsFixtures.user_fixture()

      {:ok, another_member} =
        Api.Companies.add_member(another_user.id, company, %{role: :company_admin})

      another_storyline = private_storyline_fixture(another_member)
      Api.Storylines.add_collaborator(another_storyline, member.id, another_member)
      screen_fixture(another_storyline)

      another_storyline = another_storyline |> Api.Repo.reload()

      assert {:ok, %{demo: demo}} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:ok, %{demo: demo_of_another_member}} =
               Demos.create_demo(
                 another_storyline.id,
                 @valid_attrs |> Map.merge(%{is_shared: false}),
                 another_member
               )

      returned_demos = Demos.list_all_demos(company.id, member.id)

      assert returned_demos === [demo_of_another_member, demo]
    end

    test "list_demos/1 returns all demos of a storyline", %{
      public_storyline: public_storyline,
      member: member
    } do
      another_storyline = public_storyline_fixture(member)
      screen_fixture(another_storyline)

      another_storyline = another_storyline |> Api.Repo.reload()

      assert {:ok, %{demo: demo}} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:ok, %{demo: demo_for_different_storyline}} =
               Demos.create_demo(another_storyline.id, @valid_attrs, member)

      assert {:ok, returned_demos} = Demos.list_demos(public_storyline.id, member)
      assert returned_demos === [demo]

      assert {:ok, returned_demos_of_another_storyline} =
               Demos.list_demos(another_storyline.id, member)

      assert returned_demos_of_another_storyline === [demo_for_different_storyline]
    end

    test "get_demo!/1 returns a demo with given id", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)
      assert Demos.get_demo!(demo.id) == demo
    end

    test "fetch_demo/2 returns a demo with given id", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)
      assert {:ok, returned_demo} = Demos.fetch_demo(demo.id, member)
      assert returned_demo.id == demo.id
    end

    test "get_active_demo_version!/1 returns an active demo version with given demo id", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo, active_demo_version: demo_version} = public_storyline |> demo_fixture(member)
      assert %DemoVersion{} = active_demo_version = Demos.get_active_demo_version!(demo.id)
      assert active_demo_version.id == demo_version.id
    end

    test "get_active_demo_version!/1 returns an updated active demo version with given demo id after updating",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      %{demo: demo} = public_storyline |> demo_fixture(member)

      assert {:ok, %{demo_version: new_demo_version}} =
               Demos.create_new_demo_version(
                 public_storyline.id,
                 demo.id,
                 @valid_attrs,
                 member
               )

      assert %DemoVersion{} = active_version = Demos.get_active_demo_version!(demo.id)
      assert active_version.id == new_demo_version.id
      assert new_demo_version.demo_id == demo.id
    end

    test "create_demo/2 with valid data creates a demo and and its active demo version",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      assert {:ok, %{demo_version: demo_version, demo: demo}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert demo.storyline_id == public_storyline.id
      assert demo.active_version_id == demo_version.id

      assert demo_version.created_by_id == member.id
      assert demo_version.demo_id == demo.id
    end

    test "create_demo/2 with existing edit creates a demo successfully",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      screen = Api.StorylinesFixtures.screen_fixture(public_storyline)

      Editing.add_edit(screen.id, %{
        kind: :link,
        css_selector: "first",
        dom_selector: nil,
        link_edit_props: %{destination: %{kind: "screen", id: screen.id}},
        last_edited_at: DateTime.utc_now()
      })

      assert {:ok, %{demo_version: demo_version, demo: demo}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert demo.storyline_id == public_storyline.id
      assert demo.active_version_id == demo_version.id
    end

    test "create_demo/2 with existing binding edit and variables list creates a demo successfully",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      screen = Api.StorylinesFixtures.screen_fixture(public_storyline)

      Editing.add_edit(screen.id, %{
        kind: :link,
        css_selector: "first",
        link_edit_props: %{destination: %{kind: "screen", id: screen.id}},
        last_edited_at: DateTime.utc_now()
      })

      Editing.add_edit(screen.id, %{
        kind: :binding,
        css_selector: "first",
        binding_edit_props: %{
          program_embed:
            "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@args\":[{\"@name\":\"name\",\"@value\":\"name test\"},{\"@name\":\"defaultValue\",\"@value\":\"default value\"},{\"@name\":\"description\",\"@value\":\"desc\"}],\"@fnName\":\"PUBLIC_FIELD\",\"@id\":\"ef44f562-1d5e-4d38-bf59-7ef7a402380d\",\"@type\":\"Call\"}}",
          original_text: "original text"
        },
        last_edited_at: DateTime.utc_now()
      })

      assert {:ok, %{demo_version: demo_version, demo: demo}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member, [
                 %{id: "123", name: "name test", value: "Marina"}
               ])

      assert demo.storyline_id == public_storyline.id
      assert demo.active_version_id == demo_version.id
    end

    test "create_new_demo_version/2 with variables list creates a demo version and replaces demo's active version",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      screen = Api.StorylinesFixtures.screen_fixture(public_storyline)

      Editing.add_edit(screen.id, %{
        kind: :link,
        css_selector: "first",
        link_edit_props: %{destination: %{kind: "screen", id: screen.id}},
        last_edited_at: DateTime.utc_now()
      })

      Editing.add_edit(screen.id, %{
        kind: :binding,
        css_selector: "first",
        binding_edit_props: %{
          program_embed:
            "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@args\":[{\"@name\":\"name\",\"@value\":\"name test\"},{\"@name\":\"defaultValue\",\"@value\":\"default value\"},{\"@name\":\"description\",\"@value\":\"desc\"}],\"@fnName\":\"PUBLIC_FIELD\",\"@id\":\"ef44f562-1d5e-4d38-bf59-7ef7a402380d\",\"@type\":\"Call\"}}",
          original_text: "original text"
        },
        last_edited_at: DateTime.utc_now()
      })

      assert {:ok, %{demo_version: _demo_version, demo: demo}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member, [
                 %{id: "123", name: "name test", value: "Marina"}
               ])

      assert {:ok, %{demo_version: new_demo_version}} =
               Demos.create_new_demo_version(
                 public_storyline.id,
                 demo.id,
                 @valid_attrs,
                 member,
                 [
                   %{id: "123", name: "name test", value: "New Value"}
                 ]
               )

      assert %DemoVersion{} = active_version = Demos.get_active_demo_version!(demo.id)
      assert active_version.id == new_demo_version.id
      assert new_demo_version.demo_id == demo.id

      new_demo_version =
        new_demo_version
        |> Repo.preload(:flows)
        |> Repo.preload(:start_screen)

      demo_version_flow = new_demo_version.flows |> Enum.at(0) |> Repo.preload(:screens)

      demo_last_screen =
        demo_version_flow.screens
        |> Enum.at((demo_version_flow.screens |> Enum.count()) - 1)
        |> Repo.preload(:edits)

      assert demo_last_screen.edits |> Enum.count() == 2

      binding_edit =
        Enum.find(demo_last_screen.edits, fn edit ->
          edit.kind == :binding
        end)

      binding_args = binding_edit.binding_edit_props.program_embed.expression.args

      updated_arg =
        Enum.find(binding_args, fn arg ->
          arg.name == "defaultValue"
        end)

      assert updated_arg.value == "New Value"
    end

    test "create_demo/2 with valid data copies annotations for demo version",
         %{
           public_storyline: public_storyline,
           default_flow: default_flow,
           member: member,
           guide: guide
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      annotation = annotation_point_fixture(guide, screen.id, member)

      assert {:ok, %{demo_version: demo_version}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member)

      demo_version =
        demo_version
        |> Repo.preload(:guides)

      demo_version_guide = demo_version.guides |> Enum.at(0) |> Repo.preload(:annotations)

      assert demo_version.guides |> Enum.count() == 1
      assert demo_version_guide.annotations |> Enum.count() == 1

      assert demo_version_guide.annotations |> Enum.at(0) |> Map.get(:message) ==
               annotation.message
    end

    test "create_demo/2 with valid data copies flows and screens for demo version",
         %{
           public_storyline: public_storyline,
           default_flow: default_flow,
           member: member
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens

      assert {:ok, %{demo_version: demo_version}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member)

      demo_version =
        demo_version
        |> Repo.preload(:flows)
        |> Repo.preload(:start_screen)
        |> Repo.preload(:default_flow)

      demo_version_flow = demo_version.flows |> Enum.at(0) |> Repo.preload(:screens)
      demo_first_screen = demo_version_flow.screens |> Enum.at(0) |> Repo.preload(:edits)
      demo_version_default_flow = demo_version.default_flow |> Repo.preload(:screens)

      assert demo_version.created_by_id == member.id
      assert demo_version.start_screen_id == public_storyline.start_screen_id

      assert demo_version_default_flow.screens |> Enum.count() ==
               default_flow.screens |> Enum.count()

      assert demo_version_flow.screens |> Enum.at(0) |> Map.get(:name) == screen.name

      assert demo_first_screen |> Map.get(:original_dimensions) |> Map.get(:width) == 1600
      assert demo_first_screen |> Map.get(:original_dimensions) |> Map.get(:height) == 761
      assert demo_first_screen |> Map.get(:url) == "some url"
      assert demo_first_screen.edits |> Enum.count() == 0
      assert demo_version_flow.name == default_flow.name
    end

    test "create_demo/2 with valid data copies the settings from the storyline to the demo version",
         %{
           public_storyline: public_storyline,
           member: member,
           company: company
         } do
      Api.Settings.update_storyline_settings(
        public_storyline.id,
        %{
          main_color: "#111111",
          guides_settings: %{
            glow_color: "#222222",
            font_color: "#333333",
            font_size: 16,
            accent_color: "#444444",
            smooth_scrolling: true,
            show_dismiss_button: false,
            show_back_button: false,
            show_main_button: false,
            main_button_text: "n3xT",
            dim_by_default: false,
            celebrate_guides_completion: false,
            show_avatar: true,
            avatar_url: "https://www.walnut.io",
            avatar_title: "Paz from Walnut"
          }
        },
        member
      )

      {:ok, origin_settings} = Api.Settings.fetch_nullable_storyline_settings(public_storyline.id)
      origin_settings = origin_settings |> Api.Repo.preload(:guides_settings)
      company = Repo.preload(company, settings: [:guide_settings])

      assert {:ok, %{demo_version: demo_version}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member)

      demo_version = demo_version |> Repo.preload(settings: [:guides_settings])

      assert_settings_are_equal(
        StorylineSettings.cascade(origin_settings, company.settings),
        demo_version.settings
      )
    end

    test "create_demo/2 with same name should throw an error", %{
      public_storyline: public_storyline,
      member: member
    } do
      assert {:ok, _demo} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:error, _demo} = Demos.create_demo(public_storyline.id, @valid_attrs, member)
    end

    test "create_demo/2 with invalid data returns error changeset", %{
      public_storyline: public_storyline,
      member: member
    } do
      assert {:error, %Ecto.Changeset{}} =
               Demos.create_demo(public_storyline.id, @invalid_attrs, member)
    end

    test "create_new_demo_version/2 with valid data creates a demo version and replaces demo's active vesrion",
         %{
           public_storyline: public_storyline,
           member: member
         } do
      assert {:ok, %{demo_version: demo_version, demo: demo}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert demo.active_version_id == demo_version.id

      assert {:ok, %{demo_version: new_demo_version, demo: updated_demo}} =
               Demos.create_new_demo_version(
                 public_storyline.id,
                 demo.id,
                 @valid_attrs,
                 member
               )

      assert updated_demo.id == demo.id
      assert updated_demo.active_version_id == new_demo_version.id
    end

    test "create_new_demo_version/2 updates demo version' annotations",
         %{
           public_storyline: public_storyline,
           default_flow: default_flow,
           member: member,
           guide: guide
         } do
      default_flow = default_flow |> Repo.preload(screens: :flow_screen)
      [screen, _screen2, _screen3, _screen4, _screen5] = default_flow.screens
      annotation_point_fixture(guide, screen.id, member)

      assert {:ok, %{demo_version: demo_version, demo: demo}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member)

      demo_version = demo_version |> Repo.preload(:guides)
      demo_version_guide = demo_version.guides |> Enum.at(0) |> Repo.preload(:annotations)
      assert demo_version_guide.annotations |> Enum.count() == 1

      annotation_point_fixture(guide, screen.id, member)

      assert {:ok, %{demo_version: new_demo_version}} =
               Demos.create_new_demo_version(
                 public_storyline.id,
                 demo.id,
                 @valid_attrs,
                 member
               )

      new_demo_version = new_demo_version |> Repo.preload(:guides)
      new_demo_version_guide = new_demo_version.guides |> Enum.at(0) |> Repo.preload(:annotations)
      assert new_demo_version_guide.annotations |> Enum.count() == 2
    end

    test "create_new_demo_version/2 with valid data copies the settings from the storyline to the demo version",
         %{
           public_storyline: public_storyline,
           company: company,
           member: member
         } do
      Api.Settings.update_storyline_settings(
        public_storyline.id,
        %{
          main_color: "#111111",
          disable_loader: true,
          guides_settings: %{
            glow_color: "#222222",
            font_color: "#333333",
            font_size: 16,
            accent_color: "#444444",
            smooth_scrolling: true,
            show_dismiss_button: false,
            show_back_button: false,
            show_main_button: false,
            main_button_text: "n3xT",
            dim_by_default: false,
            celebrate_guides_completion: false,
            show_avatar: true,
            avatar_url: "https://www.walnut.io",
            avatar_title: "Paz from Walnut"
          }
        },
        member
      )

      {:ok, origin_settings} = Api.Settings.fetch_nullable_storyline_settings(public_storyline.id)
      origin_settings = origin_settings |> Api.Repo.preload(:guides_settings)
      company = Repo.preload(company, settings: [:guide_settings])

      assert {:ok, %{demo_version: first_demo_version, demo: demo}} =
               Demos.create_demo(public_storyline.id, @valid_attrs, member)

      first_demo_version = first_demo_version |> Repo.preload(settings: [:guides_settings])

      assert_settings_are_equal(
        StorylineSettings.cascade(origin_settings, company.settings),
        first_demo_version.settings
      )

      {:ok, updated_origin_settings} =
        Api.Settings.update_storyline_settings(
          public_storyline.id,
          %{
            main_color: "#111111",
            disable_loader: true,
            guides_settings: %{
              glow_color: "#222222",
              font_color: "#333333",
              font_size: 16,
              accent_color: "#444444",
              smooth_scrolling: true,
              show_dismiss_button: false,
              show_back_button: false,
              show_main_button: false,
              main_button_text: "n3xT",
              dim_by_default: false,
              celebrate_guides_completion: false,
              show_avatar: true,
              avatar_url: "https://www.walnut.io",
              avatar_title: "Paz from Walnut"
            }
          },
          member
        )

      assert {:ok, %{demo_version: latest_demo_version}} =
               Demos.create_new_demo_version(
                 public_storyline.id,
                 demo.id,
                 @valid_attrs,
                 member
               )

      latest_demo_version = latest_demo_version |> Repo.preload(settings: [:guides_settings])
      updated_origin_settings = updated_origin_settings |> Api.Repo.preload(:guides_settings)

      assert_settings_are_equal(
        StorylineSettings.cascade(updated_origin_settings, company.settings),
        latest_demo_version.settings
      )
    end

    test "rename_demo/2 with valid data updates the demo", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)
      assert {:ok, renamed_demo} = Demos.rename_demo(demo.id, @update_attrs[:name], member)
      assert renamed_demo.name == @update_attrs[:name]
    end

    test "rename_demo/2 with invalid data returns error changeset", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)
      assert {:error, %Ecto.Changeset{}} = Demos.rename_demo(demo.id, @invalid_attrs, member)
    end

    test "update_last_played/2 should work", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)
      assert demo.last_played == nil
      current_datetime = DateTime.utc_now()
      assert {:ok, demo} = Demos.update_last_played(demo.id)
      assert demo.last_played > current_datetime
    end

    test "update_is_shared/2 with valid data updates the demo", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)
      assert {:ok, updated_demo} = Demos.update_is_shared(demo.id, true, member)
      assert updated_demo.is_shared == true
    end
  end

  describe "archive demos" do
    alias Api.Storylines.Demos
    alias Api.Storylines.Demos.Archive

    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen
    ]

    test "list_all_demos/1 returns all archived demos per company", %{
      public_storyline: public_storyline,
      company: company,
      member: member
    } do
      %{demo: _demo} = public_storyline |> demo_fixture(member)
      %{demo: _another_demo} = public_storyline |> demo_fixture(member)

      another_storyline = public_storyline_fixture(member)
      screen_fixture(another_storyline)

      another_storyline = another_storyline |> Api.Repo.reload()

      assert {:ok, %{demo: demo}} = Demos.create_demo(public_storyline.id, @valid_attrs, member)

      assert {:ok, %{demo: demo_for_different_storyline}} =
               Demos.create_demo(another_storyline.id, @valid_attrs, member)

      returned_demos = Archive.list_all_demos(company.id, member.id)
      assert returned_demos === []

      assert {:ok, demo} = Archive.archive(demo, member)

      assert {:ok, demo_for_different_storyline} =
               Archive.archive(demo_for_different_storyline, member)

      returned_demos = Archive.list_all_demos(company.id, member.id)

      demo_1_id = demo_for_different_storyline.id
      demo_2_id = demo.id
      assert [%{id: ^demo_1_id}, %{id: ^demo_2_id}] = returned_demos
    end

    test "list/1 returns all archived demos of a storyline", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)

      assert {:ok, returned_demos} = Archive.list_demos(public_storyline.id, member)
      assert returned_demos === []

      assert {:ok, demo} = Archive.archive(demo, member)
      assert {:ok, returned_demos} = Archive.list_demos(public_storyline.id, member)
      demo_id = demo.id
      assert [%Demo{id: ^demo_id}] = returned_demos
    end

    test "list/1 returns only non archived demos of a storyline", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)

      assert {:ok, returned_demos} = Demos.list_demos(public_storyline.id, member)
      assert returned_demos === [demo]

      assert {:ok, _demo} = Archive.archive(demo, member)

      assert {:ok, returned_demos} = Demos.list_demos(public_storyline.id, member)
      assert returned_demos === []
    end

    test "restore/1 restore a demo", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)

      {:ok, demo} = Archive.archive(demo, member)
      assert {:ok, returned_demos} = Demos.list_demos(public_storyline.id, member)
      assert returned_demos === []

      assert {:ok, demo} = Archive.restore(demo, member)
      assert {:ok, returned_demos} = Demos.list_demos(public_storyline.id, member)
      demo_id = demo.id
      assert [%Demo{id: ^demo_id}] = returned_demos
    end
  end

  describe "demo gate  - protection " do
    alias Api.Storylines.Demos
    alias Api.Storylines.Demos.DemoGate

    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen
    ]

    test "require_email/2 updates demo to require email", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)
      assert {:ok, updated_demo} = demo |> DemoGate.require_email(member)
      assert updated_demo.email_required == true
    end

    test "disable_email/2 updated demo to not require email", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo} = public_storyline |> demo_fixture(member)
      assert {:ok, updated_demo} = demo |> DemoGate.disable_email(member)
      assert updated_demo.email_required == false
    end
  end

  defp assert_settings_are_equal(origin_settings, copied_settings) do
    assert copied_settings.main_color == origin_settings.main_color
    assert copied_settings.secondary_color == origin_settings.secondary_color
    assert copied_settings.global_js == origin_settings.global_js
    assert copied_settings.global_css == origin_settings.global_css
    assert copied_settings.disable_loader == origin_settings.disable_loader

    assert copied_settings.guides_settings.show_glow ==
             origin_settings.guides_settings.show_glow

    assert copied_settings.guides_settings.glow_color ==
             origin_settings.guides_settings.glow_color

    assert copied_settings.guides_settings.background_color ==
             origin_settings.guides_settings.background_color

    assert copied_settings.guides_settings.font_color ==
             origin_settings.guides_settings.font_color

    assert copied_settings.guides_settings.font_size ==
             origin_settings.guides_settings.font_size

    assert copied_settings.guides_settings.accent_color ==
             origin_settings.guides_settings.accent_color

    assert copied_settings.guides_settings.smooth_scrolling ==
             origin_settings.guides_settings.smooth_scrolling

    assert copied_settings.guides_settings.show_dismiss_button ==
             origin_settings.guides_settings.show_dismiss_button

    assert copied_settings.guides_settings.show_back_button ==
             origin_settings.guides_settings.show_back_button

    assert copied_settings.guides_settings.show_back_button ==
             origin_settings.guides_settings.show_back_button

    assert copied_settings.guides_settings.show_main_button ==
             origin_settings.guides_settings.show_main_button

    assert copied_settings.guides_settings.main_button_text ==
             origin_settings.guides_settings.main_button_text

    assert copied_settings.guides_settings.dim_by_default ==
             origin_settings.guides_settings.dim_by_default

    assert copied_settings.guides_settings.celebrate_guides_completion ==
             origin_settings.guides_settings.celebrate_guides_completion

    assert copied_settings.guides_settings.show_avatar ==
             origin_settings.guides_settings.show_avatar

    assert copied_settings.guides_settings.avatar_url ==
             origin_settings.guides_settings.avatar_url

    assert copied_settings.guides_settings.avatar_title ==
             origin_settings.guides_settings.avatar_title
  end
end
