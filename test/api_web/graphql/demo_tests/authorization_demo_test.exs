defmodule ApiWeb.GraphQL.DemoAuthorizationTest do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/Demo.gql")

  def assert_ok_and_get_demo(demo_id, context) do
    assert {:ok, query_data} = query_gql(variables: %{"id" => demo_id}, context: context)
    no_errors!(query_data)
    get_in(query_data, [:data, "demo"])
  end

  def assert_error_unauthorized(demo_id, context) do
    assert {
             :ok,
             %{
               errors: [
                 %{
                   code: :unauthorized,
                   message: "Unauthorized",
                   path: ["demo"],
                   status_code: 403
                 }
               ],
               data: %{"demo" => nil}
             }
           } = query_gql(variables: %{"id" => demo_id}, context: context)
  end

  def context(member) do
    %{current_member: member}
  end

  def setup_data do
    user = user_fixture()
    user2 = user_fixture()
    user_admin = Api.AccountsFixtures.user_admin_fixture()
    company = Api.CompaniesFixtures.company_fixture()
    {:ok, member} = Api.Companies.add_member(user.id, company)
    {:ok, member2} = Api.Companies.add_member(user2.id, company)
    {:ok, member_admin} = Api.Companies.add_member(user_admin.id, company)

    storyline = Api.StorylineCreationFixtures.public_storyline_creation_fixture(member)
    screen_fixture(storyline)
    storyline = storyline |> Api.Repo.reload()

    %{demo: shared_demo} =
      storyline
      |> demo_fixture(member)

    %{demo: not_shared_demo} =
      storyline
      |> demo_fixture(member, %{
        is_shared: false
      })

    %{
      user: user,
      user2: user2,
      user_admin: user_admin,
      member_admin: member_admin,
      member: member,
      member2: member2,
      company: company,
      storyline: storyline,
      shared_demo: shared_demo,
      not_shared_demo: not_shared_demo
    }
  end

  describe "Demo for unauthenticated user" do
    setup do
      setup_data()
    end

    test "allows access when demo is_shared true", %{
      shared_demo: demo
    } do
      assert_ok_and_get_demo(demo.id, nil)
    end

    test "forbids access when demo is_shared false", %{
      not_shared_demo: demo
    } do
      assert_error_unauthorized(demo.id, nil)
    end
  end

  describe "Demo for authenticated user" do
    setup do
      setup_data()
    end

    test "allows access when demo accessed via admin", %{
      member_admin: member_admin,
      not_shared_demo: demo
    } do
      assert_ok_and_get_demo(demo.id, context(member_admin))
    end

    test "allows access when demo is_shared true", %{
      member: member,
      shared_demo: demo
    } do
      assert_ok_and_get_demo(demo.id, context(member))
    end

    test "allows access when demo is_shared false and user is owner", %{
      member: member,
      not_shared_demo: demo
    } do
      assert_ok_and_get_demo(demo.id, context(member))
    end

    test "allows access when demo is_shared false and user is collaborator", %{
      storyline: storyline,
      member2: member2,
      not_shared_demo: demo,
      member: member
    } do
      Api.Storylines.add_collaborator(storyline, member2.id, member)

      assert_ok_and_get_demo(demo.id, context(member2))
    end

    test "forbids access when demo is_shared false and user isnt a collaborator of a private storyline",
         %{
           member: member,
           member2: member2
         } do
      private_storyline = Api.StorylineCreationFixtures.private_storyline_creation_fixture(member)
      screen_fixture(private_storyline)
      private_storyline = private_storyline |> Api.Repo.reload()

      %{demo: demo} =
        private_storyline
        |> demo_fixture(member, %{
          is_shared: false
        })

      assert_error_unauthorized(demo.id, context(member2))
    end
  end
end
