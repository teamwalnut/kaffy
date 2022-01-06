defmodule Api.ArchivedStorylinesTest do
  use Api.DataCase, async: true

  alias Api.Storylines
  alias Api.Storylines.Storyline

  setup [:setup_user, :setup_company, :setup_member, :setup_public_storyline, :setup_collaborator]

  describe "storylines" do
    @valid_attrs %{name: "some name"}
    # @update_attrs %{last_edited: "2011-05-18T15:01:01Z", name: "some updated name"}

    def member_for_company_fixture(company, attrs \\ %{}) do
      user = user_fixture()

      {:ok, member} = Api.Companies.add_member(user.id, company, attrs)
      member
    end

    test "list_all_storylines/0 doesnt return archived storylines", %{
      member: member,
      public_storyline: public_storyline
    } do
      member = member |> Api.Repo.preload(:company)
      member2 = member_for_company_fixture(member.company)

      public_storyline2 = Api.StorylinesFixtures.public_storyline_fixture(member2, @valid_attrs)

      private_storyline = Api.StorylinesFixtures.private_storyline_fixture(member, @valid_attrs)

      {:ok, _} = Storylines.Archived.archive(public_storyline2, member2)

      owner = public_storyline |> Api.Repo.preload(:owner) |> Map.get(:owner)

      assert Storylines.list_all_storylines(owner.id, owner.company_id) == [
               private_storyline,
               public_storyline
             ]
    end

    test "list_private_storylines/0 doesnt return archived storylines", %{member: member} do
      member = member |> Api.Repo.preload(:company)
      member2 = member_for_company_fixture(member.company)

      private_storyline = Api.StorylinesFixtures.private_storyline_fixture(member, @valid_attrs)
      {:ok, _} = Storylines.Archived.archive(private_storyline, member)

      _private_storyline2 =
        Api.StorylinesFixtures.private_storyline_fixture(member2, @valid_attrs)

      _public_storyline = Api.StorylinesFixtures.public_storyline_fixture(member, @valid_attrs)

      assert Storylines.list_private_storylines(member.id, member.company_id) == []
    end

    test "list_public_storylines/0 doesnt return archived storylines", %{
      member: member,
      public_storyline: public_storyline
    } do
      member = member |> Api.Repo.preload(:company)
      member2 = member_for_company_fixture(member.company)

      public_storyline2 = Api.StorylinesFixtures.public_storyline_fixture(member2, @valid_attrs)

      _private_storyline2 = Api.StorylinesFixtures.private_storyline_fixture(member, @valid_attrs)
      {:ok, _} = Api.Storylines.Archived.archive(public_storyline2, member2)

      assert Storylines.list_public_storylines(member.company_id) == [
               public_storyline
             ]
    end

    test "archive/1 removed collaborators", %{public_storyline: public_storyline, member: member} do
      {:ok, %{archived_storyline: archived_storyline}} =
        Storylines.Archived.archive(public_storyline, member)

      archived_storyline = archived_storyline |> Repo.preload(:collaborators, force: true)
      assert archived_storyline.collaborators == []
    end

    test "restore/1 restores a storyline", %{member: member, public_storyline: public_storyline} do
      member = member |> Api.Repo.preload(:company)

      {:ok, %{archived_storyline: storyline}} =
        Storylines.Archived.archive(public_storyline, member)

      assert Storylines.list_all_storylines(member.id, member.company_id) == []

      {:ok, storyline} = Storylines.Archived.restore(storyline, member)

      storyline_id = storyline.id

      assert [%Storyline{id: ^storyline_id}] =
               Storylines.list_all_storylines(member.id, member.company_id)
    end

    test "list/2 lists archived storylines only", %{
      member: member,
      public_storyline: public_storyline
    } do
      member = member |> Api.Repo.preload(:company)

      {:ok, %{archived_storyline: storyline}} =
        Storylines.Archived.archive(public_storyline, member)

      storyline_id = storyline.id

      assert [%Storyline{id: ^storyline_id}] =
               Storylines.Archived.list(member.id, member.company_id)
    end
  end
end
