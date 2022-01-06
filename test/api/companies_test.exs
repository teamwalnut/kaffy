defmodule Api.CompaniesTest do
  use Api.DataCase, async: true
  alias Api.Companies

  describe "companies" do
    alias Api.Companies.Company
    setup [:setup_user, :setup_company]
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    test "get_company!/1 returns the company with given id", %{company: company} do
      assert Companies.get_company!(company.id) == company
    end

    test "create_company/1 with valid data creates a company" do
      assert {:ok, %Company{} = company} = Companies.create_company(%{name: "some name"})
      assert company.name == "some name"
    end

    test "create_company/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Companies.create_company(@invalid_attrs)
    end

    test "update_company/2 with valid data updates the company", %{company: company} do
      assert {:ok, %Company{} = company} = Companies.update_company(company, @update_attrs)
      assert company.name == "some updated name"
    end

    test "update_company/2 with invalid data returns error changeset", %{company: company} do
      assert {:error, %Ecto.Changeset{}} = Companies.update_company(company, @invalid_attrs)
      assert company == Companies.get_company!(company.id)
    end

    test "delete_company/1 deletes the company", %{company: company} do
      assert {:ok, %Company{}} = Companies.delete_company(company)
      assert_raise Ecto.NoResultsError, fn -> Companies.get_company!(company.id) end
    end
  end

  describe "members" do
    alias Api.Companies.Member
    setup [:setup_user, :setup_company, :setup_member]

    test "list_members/1 returns all members", %{company: company, member: member} do
      assert Companies.list_members(company) == [member]
    end

    test "get_member!/1 returns the member with given id", %{member: member} do
      assert Companies.get_member!(member.id) == member
    end

    test "add_member/1 with valid data creates a member", %{company: company} do
      user = user_fixture()

      assert {:ok, %Member{} = member} =
               Companies.add_member(user.id, company, %{role: :presenter})

      assert member.role == :presenter
    end

    test "add_member/1 when that user already has a member fails", %{company: company} do
      user = user_fixture()
      company2 = company_fixture()

      assert {:ok, %Member{}} = Companies.add_member(user.id, company, %{role: :presenter})

      assert {:error, "user already a member of a company"} =
               Companies.add_member(user.id, company2, %{role: :presenter})
    end

    test "delete_member/1 deletes the member", %{company: company, member: member} do
      user = user_fixture()
      {:ok, new_member} = Companies.add_member(user.id, company)

      assert {:ok, %Member{}} = Companies.delete_member(new_member, member)
      assert_raise Ecto.NoResultsError, fn -> Companies.get_member!(new_member.id) end
    end

    test "get_member_by_email/2 returns a member when called with existing and correct company_id and email",
         %{user: user, company: company, member: member} do
      assert member == Companies.get_member_by_email(user.email, company.id)
    end

    test "get_member_by_email/2 returns nil if member can't be found",
         %{company: company} do
      assert is_nil(Companies.get_member_by_email("randomemail@gmail.com", company.id))
    end

    test "update_member_role/2 updated member role and returns member",
         %{member: member, company: company} do
      another_user = user_fixture()
      {:ok, another_member} = Api.Companies.add_member(another_user.id, company)
      assert member.role == :company_admin
      assert {:ok, %Member{} = updated_member} = Companies.update_member_role(member, :viewer)
      assert updated_member.role == :viewer

      assert {:error,
              "You cannot downgrade this user since a company must have at lease one Admin. Set a different admin to downgrade this user."} =
               Companies.update_member_role(another_member, :viewer)

      assert {:ok, %Member{} = _updated_member} =
               Companies.update_member_role(member, :company_admin)
    end

    test "update_member_role/2  throws when trying to change the only admin in the company",
         %{member: member} do
      assert member.role == :company_admin

      assert {:error,
              "You cannot downgrade this user since a company must have at lease one Admin. Set a different admin to downgrade this user."} =
               Companies.update_member_role(member, :viewer)
    end
  end
end
