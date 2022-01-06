defmodule Api.PatchingTest do
  use Api.DataCase, async: true

  alias Api.Patching

  describe "company patches" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member
    ]

    test "fails trying to add a patch to non-existing company", %{member: member} do
      {:error, :not_found} =
        Patching.add_company_patch(
          Ecto.UUID.generate(),
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )
    end

    test "allows adding a patch to a company", %{company: company, member: member} do
      {:ok, patch} =
        Patching.add_company_patch(
          company.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      patches = Patching.list_company_patches(company.id)
      assert patch in patches
    end

    # Note(Danni): waiting on this ticket: https://github.com/mathieuprog/polymorphic_embed/issues/28
    test "fails adding a patch when fields are missing", %{company: company, member: member} do
      {:error, _} =
        Patching.add_company_patch(
          company.id,
          %{
            css_selector: ".selector",
            html: "<im>html</im>",
            __type__: :html_patch
          },
          "test",
          member
        )
    end

    test "correctly listing company patches", %{company: company, member: member} do
      company2 = Api.CompaniesFixtures.company_fixture()

      {:ok, patch} =
        Patching.add_company_patch(
          company.id,
          Api.PatchingFixtures.unique_html_patch(),
          "Test",
          member
        )

      {:ok, patch2} =
        Patching.add_company_patch(
          company2.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      patches = Patching.list_company_patches(company.id)
      assert patch in patches
      assert patch2 not in patches
    end
  end

  describe "storyline patches" do
    setup [
      :setup_user,
      :setup_company,
      :setup_member,
      :setup_public_storyline,
      :setup_screen
    ]

    test "fails trying to add a patch to non-existing storyline", %{member: member} do
      {:error, :not_found} =
        Patching.add_storyline_patch(
          Ecto.UUID.generate(),
          Api.PatchingFixtures.unique_html_patch(),
          "name",
          member
        )
    end

    test "allows adding a patch to a storyline", %{public_storyline: storyline, member: member} do
      {:ok, patch} =
        Patching.add_storyline_patch(
          storyline.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      patches = Patching.list_storyline_patches(storyline.id)
      assert patch in patches
    end

    test "correctly listing storyline patches", %{public_storyline: storyline, member: member} do
      storyline2 = Api.StorylinesFixtures.private_storyline_fixture(member)

      {:ok, patch} =
        Patching.add_storyline_patch(
          storyline.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      {:ok, patch2} =
        Patching.add_storyline_patch(
          storyline2.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      patches = Patching.list_storyline_patches(storyline.id)
      assert patch in patches
      assert patch2 not in patches
    end

    test "add_patches/2 adds the patches correctly to the storyline", %{
      company: company,
      public_storyline: storyline,
      member: member
    } do
      {:ok, patch1} =
        Patching.add_company_patch(
          company.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      {:ok, patch2} =
        Patching.add_company_patch(
          company.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      {:ok, _patches} = Patching.add_patches(storyline, [patch1, patch2], member)

      patches = Patching.list_storyline_patches(storyline.id) |> Enum.map(fn p -> p.data end)

      assert patch1.data in patches
      assert patch2.data in patches
    end

    test "update_patch/2 allows updating a patch", %{public_storyline: storyline, member: member} do
      {:ok, patch} =
        Patching.add_storyline_patch(
          storyline.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      mock_css_selector = "walnut > all"
      attrs = %{css_selector: mock_css_selector, html: "<div>asd</div>"}
      {:ok, updated_patch} = Patching.update_patch(patch, attrs, member)
      assert updated_patch.data.css_selector == mock_css_selector
    end

    test "remove_patch/1 allows to remove a patch", %{public_storyline: storyline, member: member} do
      {:ok, patch} =
        Patching.add_storyline_patch(
          storyline.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      assert {:ok, deleted_patch} = Patching.remove_patch(patch, member)
      assert deleted_patch.id == patch.id

      assert_raise Ecto.NoResultsError, fn ->
        Patching.get_patch!(patch.id)
      end
    end

    test "allows adding a patch to a demo version", %{
      public_storyline: public_storyline,
      member: member
    } do
      %{demo: demo, active_demo_version: demo_version} = public_storyline |> demo_fixture(member)

      {:ok, patch} =
        Patching.add_demo_patch(
          demo.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test"
        )

      assert patch.demo_version_id == demo_version.id
    end

    test "add_patches/2 adds the patches correctly to demo version", %{
      public_storyline: public_storyline,
      company: company,
      member: member
    } do
      %{demo: demo, active_demo_version: demo_version} = public_storyline |> demo_fixture(member)

      {:ok, patch1} =
        Patching.add_company_patch(
          company.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      {:ok, patch2} =
        Patching.add_company_patch(
          company.id,
          Api.PatchingFixtures.unique_html_patch(),
          "test",
          member
        )

      {:ok, patches} = Patching.add_patches(demo, [patch1, patch2], member)

      patches
      |> Enum.each(fn current_patch ->
        {:ok, %Api.Patching.Patch{demo_version_id: demo_version_id}} = current_patch
        assert demo_version_id == demo_version.id
      end)
    end
  end
end
