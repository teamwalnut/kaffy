defmodule ApiWeb.GraphQL.StorylineTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines.Editing

  load_gql(:storyline, ApiWeb.Schema, "test/support/queries/Storyline.gql")
  load_gql(:storyline_unlinked, ApiWeb.Schema, "test/support/queries/Storyline_Unlinked.gql")

  def storyline_gql_struct(storyline) do
    %{
      "id" => storyline.id,
      "lastEdited" => storyline.last_edited |> DateTime.to_iso8601(),
      "name" => storyline.name,
      "screens" => [],
      "screensCount" => 0,
      "startScreen" => nil,
      "flows" => [%{"is_default" => true, "name" => "Default", "screens" => []}],
      "guides" =>
        storyline.guides
        |> Enum.sort_by(fn guide -> guide.priority end)
        |> Enum.map(fn guide -> %{"id" => guide.id, "priority" => guide.priority} end)
    }
  end

  def assert_ok_and_get_storyline(storyline_id, context) do
    assert {:ok, query_data} =
             query_gql_by(:storyline, variables: %{"id" => storyline_id}, context: context)

    no_errors!(query_data)
    get_in(query_data, [:data, "storyline"])
  end

  def assert_error_unauthorized(storyline_id, context) do
    assert {
             :ok,
             %{
               errors: [
                 %{
                   code: :unauthorized,
                   locations: [%{column: 3, line: 2}],
                   message: "Unauthorized",
                   path: ["storyline"],
                   status_code: 403
                 }
               ],
               data: %{"storyline" => nil}
             }
           } = query_gql_by(:storyline, variables: %{"id" => storyline_id}, context: context)
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

    private_storyline = Api.StorylineCreationFixtures.private_storyline_creation_fixture(member)
    guide_fixture(private_storyline)
    guide_fixture(private_storyline)

    private_storyline =
      private_storyline
      |> Repo.preload(:guides)

    public_storyline = Api.StorylineCreationFixtures.public_storyline_creation_fixture(member)
    guide_fixture(public_storyline)
    guide_fixture(public_storyline)

    public_storyline =
      public_storyline
      |> Repo.preload(:guides)

    %{
      user: user,
      user2: user2,
      member2: member2 |> Repo.preload([:company, :user]),
      user_admin: user_admin,
      member_admin: member_admin |> Repo.preload([:company, :user]),
      member: member |> Repo.preload([:company, :user]),
      company: company,
      private_storyline: private_storyline,
      public_storyline: public_storyline
    }
  end

  describe "Storyline for unauthenticated user" do
    setup do
      setup_data()
    end

    test "forbids access", %{
      private_storyline: storyline
    } do
      assert_error_unauthorized(storyline.id, context(nil))
    end

    test "forbids access is_public true", %{
      public_storyline: storyline
    } do
      assert_error_unauthorized(storyline.id, context(nil))
    end
  end

  describe "Storyline for authenticated user" do
    setup do
      setup_data()
    end

    test "allows access when storyline accessed via admin", %{
      member_admin: member_admin,
      private_storyline: storyline
    } do
      # note(itay): There are several scenarios where you can be authenicated and be an admin
      # I'm testing the one where the admin is not a collaborator / in the company of the
      # owner of the storyline, as that's the most interesting I think
      got_storyline = assert_ok_and_get_storyline(storyline.id, context(member_admin))
      assert storyline_gql_struct(storyline) == got_storyline
    end

    test "allows access when storyline is_public true", %{
      member: member,
      public_storyline: storyline
    } do
      got_storyline = assert_ok_and_get_storyline(storyline.id, context(member))
      assert storyline_gql_struct(storyline) == got_storyline
    end

    test "allows access when storyline is_public false and user is owner", %{
      member: member,
      private_storyline: storyline
    } do
      got_storyline = assert_ok_and_get_storyline(storyline.id, context(member))
      assert storyline_gql_struct(storyline) == got_storyline
    end

    test "allows access when storyline is_shared false and user is collaborator", %{
      member2: member2,
      member: member,
      private_storyline: storyline
    } do
      Api.Storylines.add_collaborator(storyline, member2.id, member)

      got_storyline = assert_ok_and_get_storyline(storyline.id, context(member2))
      assert storyline_gql_struct(storyline) == got_storyline
    end

    test "forbids access when storyline is_shared false and user isnt a collaborator", %{
      member2: member2,
      private_storyline: storyline
    } do
      assert_error_unauthorized(storyline.id, context(member2))
    end

    test "forbids access when storyline is accessed from a different company", %{
      public_storyline: storyline
    } do
      user = Api.AccountsFixtures.user_fixture()
      %{member: outside_company_member} = Api.CompaniesFixtures.company_and_member_fixture(user)
      assert_error_unauthorized(storyline.id, context(outside_company_member))
    end

    test "screens are ordered ascending", %{
      member: member,
      private_storyline: storyline
    } do
      import Ecto.Query
      alias Api.Storylines.Screen

      screen1 = Api.StorylinesFixtures.screen_fixture(storyline)
      screen2 = Api.StorylinesFixtures.screen_fixture(storyline)
      screen1_id = screen1.id
      screen2_id = screen2.id

      from(screen in Screen, where: screen.id == ^screen1.id)
      |> Repo.update_all(set: [updated_at: DateTime.utc_now()])

      from(screen in Screen, where: screen.id == ^screen2.id)
      |> Repo.update_all(set: [updated_at: DateTime.utc_now()])

      assert {:ok,
              %{
                data: %{
                  "storyline" => %{
                    "screens" => [%{"id" => ^screen1_id}, %{"id" => ^screen2_id}]
                  }
                }
              }} =
               query_gql_by(:storyline,
                 variables: %{"id" => storyline.id},
                 context: context(member)
               )

      from(screen in Screen, where: screen.id == ^screen2.id)
      |> Repo.update_all(set: [updated_at: DateTime.utc_now()])

      from(screen in Screen, where: screen.id == ^screen1.id)
      |> Repo.update_all(set: [updated_at: DateTime.utc_now()])

      assert {:ok,
              %{
                data: %{
                  "storyline" => %{
                    "screens" => [%{"id" => ^screen2_id}, %{"id" => ^screen1_id}]
                  }
                }
              }} =
               query_gql_by(:storyline,
                 variables: %{"id" => storyline.id},
                 context: context(member)
               )
    end
  end

  describe "unlinked screens" do
    setup do
      setup_data()
    end

    test "correctly mark unlinked screens", %{member: member, private_storyline: storyline} do
      screen1 = Api.StorylinesFixtures.screen_fixture(storyline)
      screen2 = Api.StorylinesFixtures.screen_fixture(storyline)
      _screen3 = Api.StorylinesFixtures.screen_fixture(storyline)

      Editing.add_edit(screen1.id, %{
        kind: :link,
        css_selector: "first",
        dom_selector: nil,
        link_edit_props: %{destination: %{kind: "screen", id: screen2.id}},
        last_edited_at: DateTime.utc_now()
      })

      query_gql_by(:storyline_unlinked,
        variables: %{"id" => storyline.id},
        context: context(member)
      )
      |> match_snapshot()
    end
  end
end
