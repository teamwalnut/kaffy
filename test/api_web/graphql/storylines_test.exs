defmodule ApiWeb.GraphQL.StorylinesTest do
  use ApiWeb.GraphQLCase, async: true

  load_gql(
    :list_storylines,
    ApiWeb.Schema,
    "test/support/queries/Storylines.gql"
  )

  setup [:register_and_log_in_user]

  describe "Storylines" do
    test "Returns all for given member company", %{context: context, user: user} do
      company = Api.CompaniesFixtures.company_fixture()
      {:ok, member} = Api.Companies.add_member(user.id, company)

      company2 = Api.CompaniesFixtures.company_fixture()
      user2 = Api.AccountsFixtures.user_fixture()
      {:ok, member2} = Api.Companies.add_member(user2.id, company2)
      member = member |> Api.Repo.preload([:user, :company])
      storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
      storyline2 = Api.StorylinesFixtures.private_storyline_fixture(member)
      _storyline3 = Api.StorylinesFixtures.private_storyline_fixture(member2)

      assert {:ok, query_data} =
               query_gql_by(
                 :list_storylines,
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      storylines = get_in(query_data, [:data, "storylines"])
      storyline = storyline |> Api.Repo.preload(:flows)

      default_flow =
        storyline.flows |> Enum.at(0) |> Api.Repo.preload(:screens) |> map_flow_to_gql_struct

      storyline2 = storyline2 |> Api.Repo.preload(:flows)

      default_flow2 =
        storyline2.flows |> Enum.at(0) |> Api.Repo.preload(:screens) |> map_flow_to_gql_struct

      assert storylines == [
               %{
                 "id" => storyline2.id,
                 "isPublic" => storyline2.is_public,
                 "archivedAt" => nil,
                 "screensCount" => 0,
                 "owner" => %{
                   "user" => %{
                     "email" => member.user.email,
                     "firstName" => member.user.first_name,
                     "lastName" => member.user.last_name
                   },
                   "company_id" => member.company.id
                 },
                 "collaborators" => [],
                 "flows" => [default_flow2],
                 "patches" => []
               },
               %{
                 "id" => storyline.id,
                 "isPublic" => storyline.is_public,
                 "archivedAt" => nil,
                 "screensCount" => 0,
                 "owner" => %{
                   "user" => %{
                     "email" => member.user.email,
                     "firstName" => member.user.first_name,
                     "lastName" => member.user.last_name
                   },
                   "company_id" => member.company.id
                 },
                 "collaborators" => [],
                 "flows" => [default_flow],
                 "patches" => []
               }
             ]
    end

    test "Returns only public storylines", %{context: context, user: user} do
      company = Api.CompaniesFixtures.company_fixture()
      {:ok, member} = Api.Companies.add_member(user.id, company)
      member = member |> Api.Repo.preload([:user, :company])
      public_storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
      _private_storyline = Api.StorylinesFixtures.private_storyline_fixture(member)

      assert {:ok, query_data} =
               query_gql_by(
                 :list_storylines,
                 variables: %{"visibility" => "PUBLIC"},
                 context: context
               )

      no_errors!(query_data)
      storylines = get_in(query_data, [:data, "storylines"])
      public_storyline = public_storyline |> Api.Repo.preload(:flows)

      default_flow =
        public_storyline.flows
        |> Enum.at(0)
        |> Api.Repo.preload(:screens)
        |> map_flow_to_gql_struct

      assert storylines == [
               %{
                 "id" => public_storyline.id,
                 "isPublic" => public_storyline.is_public,
                 "screensCount" => 0,
                 "archivedAt" => nil,
                 "owner" => %{
                   "user" => %{
                     "email" => member.user.email,
                     "firstName" => member.user.first_name,
                     "lastName" => member.user.last_name
                   },
                   "company_id" => member.company.id
                 },
                 "collaborators" => [],
                 "flows" => [default_flow],
                 "patches" => []
               }
             ]
    end

    test "Returns only private storylines", %{context: context, user: user} do
      company = Api.CompaniesFixtures.company_fixture()
      {:ok, member} = Api.Companies.add_member(user.id, company)
      member = member |> Api.Repo.preload([:user, :company])
      _public_storyline = Api.StorylinesFixtures.public_storyline_fixture(member)
      private_storyline = Api.StorylinesFixtures.private_storyline_fixture(member)

      assert {:ok, query_data} =
               query_gql_by(
                 :list_storylines,
                 variables: %{"visibility" => "PRIVATE"},
                 context: context
               )

      no_errors!(query_data)
      storylines = get_in(query_data, [:data, "storylines"])
      private_storyline = private_storyline |> Api.Repo.preload(:flows)

      default_flow =
        private_storyline.flows
        |> Enum.at(0)
        |> Api.Repo.preload(:screens)
        |> map_flow_to_gql_struct

      assert storylines == [
               %{
                 "id" => private_storyline.id,
                 "isPublic" => private_storyline.is_public,
                 "archivedAt" => nil,
                 "screensCount" => 0,
                 "owner" => %{
                   "user" => %{
                     "email" => member.user.email,
                     "firstName" => member.user.first_name,
                     "lastName" => member.user.last_name
                   },
                   "company_id" => member.company.id
                 },
                 "collaborators" => [],
                 "flows" => [default_flow],
                 "patches" => []
               }
             ]
    end

    test "Returns the correct owner", %{context: context, user: user} do
      user2 = Api.AccountsFixtures.user_fixture()
      company = Api.CompaniesFixtures.company_fixture()
      {:ok, member} = Api.Companies.add_member(user.id, company)
      member = member |> Api.Repo.preload([:user, :company])
      {:ok, member2} = Api.Companies.add_member(user2.id, company)
      member2 = member2 |> Api.Repo.preload([:user, :company])

      storyline1 = Api.StorylinesFixtures.public_storyline_fixture(member)
      storyline2 = Api.StorylinesFixtures.public_storyline_fixture(member2)

      assert {:ok, query_data} =
               query_gql_by(
                 :list_storylines,
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      storylines = get_in(query_data, [:data, "storylines"])
      storyline1 = storyline1 |> Api.Repo.preload(:flows)

      default_flow1 =
        storyline1.flows |> Enum.at(0) |> Api.Repo.preload(:screens) |> map_flow_to_gql_struct

      storyline2 = storyline2 |> Api.Repo.preload(:flows)

      default_flow2 =
        storyline2.flows |> Enum.at(0) |> Api.Repo.preload(:screens) |> map_flow_to_gql_struct

      assert storylines == [
               %{
                 "id" => storyline2.id,
                 "isPublic" => storyline2.is_public,
                 "collaborators" => [],
                 "archivedAt" => nil,
                 "owner" => %{
                   "user" => %{
                     "email" => member2.user.email,
                     "firstName" => member2.user.first_name,
                     "lastName" => member2.user.last_name
                   },
                   "company_id" => member2.company.id
                 },
                 "screensCount" => 0,
                 "flows" => [default_flow2],
                 "patches" => []
               },
               %{
                 "id" => storyline1.id,
                 "isPublic" => storyline1.is_public,
                 "collaborators" => [],
                 "archivedAt" => nil,
                 "owner" => %{
                   "user" => %{
                     "email" => member.user.email,
                     "firstName" => member.user.first_name,
                     "lastName" => member.user.last_name
                   },
                   "company_id" => member.company.id
                 },
                 "screensCount" => 0,
                 "flows" => [default_flow1],
                 "patches" => []
               }
             ]
    end

    test "Returns collaborators correctly", %{context: context, user: user} do
      user2 = Api.AccountsFixtures.user_fixture()
      company = Api.CompaniesFixtures.company_fixture()
      {:ok, member} = Api.Companies.add_member(user.id, company)
      member = member |> Api.Repo.preload([:user, :company])
      {:ok, member2} = Api.Companies.add_member(user2.id, company)
      member2 = member2 |> Api.Repo.preload(:user)
      storyline1 = Api.StorylinesFixtures.public_storyline_fixture(member)

      {:ok, _collab} = Api.Storylines.add_collaborator(storyline1, member2.id, member)

      assert {:ok, query_data} =
               query_gql_by(
                 :list_storylines,
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      storylines = get_in(query_data, [:data, "storylines"])
      storyline1 = storyline1 |> Api.Repo.preload(:flows)

      default_flow =
        storyline1.flows |> Enum.at(0) |> Api.Repo.preload(:screens) |> map_flow_to_gql_struct

      assert storylines == [
               %{
                 "id" => storyline1.id,
                 "isPublic" => storyline1.is_public,
                 "archivedAt" => nil,
                 "collaborators" => [
                   %{
                     "member" => %{
                       "user" => %{
                         "email" => user2.email,
                         "firstName" => user2.first_name,
                         "lastName" => user2.last_name
                       }
                     }
                   }
                 ],
                 "owner" => %{
                   "user" => %{
                     "email" => member.user.email,
                     "firstName" => member.user.first_name,
                     "lastName" => member.user.last_name
                   },
                   "company_id" => member.company.id
                 },
                 "screensCount" => 0,
                 "flows" => [default_flow],
                 "patches" => []
               }
             ]
    end

    test "Returns the flows and their screens in the correct order", %{
      context: context,
      user: user
    } do
      %{member: member, company: company} = company_and_member_fixture(user)
      storyline = public_storyline_fixture(member)
      screen1 = screen_fixture(storyline)
      screen3 = screen_fixture(storyline)
      screen2 = screen_fixture(storyline)
      default_flow = default_flow_fixture(storyline.id)
      regular_flow = flow_fixture(storyline.id)

      assert {:ok, query_data} =
               query_gql_by(
                 :list_storylines,
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      storylines = get_in(query_data, [:data, "storylines"])

      assert storylines == [
               %{
                 "id" => storyline.id,
                 "isPublic" => storyline.is_public,
                 "collaborators" => [],
                 "archivedAt" => nil,
                 "owner" => %{
                   "user" => %{
                     "email" => user.email,
                     "firstName" => user.first_name,
                     "lastName" => user.last_name
                   },
                   "company_id" => company.id
                 },
                 "screensCount" => 3,
                 "patches" => [],
                 "flows" => [
                   %{
                     "id" => default_flow.id,
                     "name" => default_flow.name,
                     "is_default" => true,
                     "position" => 1,
                     "screens" => [
                       %{
                         "id" => screen1.id,
                         "name" => screen1.name
                       },
                       %{
                         "id" => screen3.id,
                         "name" => screen3.name
                       },
                       %{
                         "id" => screen2.id,
                         "name" => screen2.name
                       }
                     ]
                   },
                   %{
                     "id" => regular_flow.id,
                     "name" => regular_flow.name,
                     "is_default" => false,
                     "position" => 2,
                     "screens" => []
                   }
                 ]
               }
             ]
    end

    test "Returns the patches for the storyline", %{
      context: context,
      user: user
    } do
      %{member: member} = company_and_member_fixture(user)
      storyline = public_storyline_fixture(member)

      {:ok, patch} =
        Api.Patching.add_storyline_patch(
          storyline.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      _screen = screen_fixture(storyline)

      assert {:ok, query_data} =
               query_gql_by(
                 :list_storylines,
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)
      patches = (get_in(query_data, [:data, "storylines"]) |> Enum.at(0))["patches"]

      assert patches == [
               %{
                 "data" => %{
                   "cssSelector" => patch.data.css_selector,
                   "html" => patch.data.html,
                   "position" => patch.data.position |> Atom.to_string() |> String.upcase(),
                   "targetUrlGlob" => patch.data.target_url_glob
                 }
               }
             ]
    end
  end
end
