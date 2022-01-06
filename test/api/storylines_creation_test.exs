defmodule Api.StorylineCreationTest do
  use Api.DataCase, async: true

  setup :verify_on_exit!

  describe "patches" do
    setup [:setup_user, :setup_company, :setup_member, :setup_company_html_patch]

    test "create_public_storyline/1 adds the company patches and default flow", %{
      member: member,
      company_html_patch: patch
    } do
      assert {:ok, storyline} =
               Api.StorylineCreation.create_public_storyline(%{name: "some name"}, member)

      payloads_datas =
        Api.Patching.list_storyline_patches(storyline.id)
        |> Enum.map(fn patch -> patch.data end)

      assert patch.data in payloads_datas
    end

    test "create_public_storyline/1 returns an error correctly", %{
      member: member
    } do
      {
        :error,
        %Ecto.Changeset{}
      } = Api.StorylineCreation.create_public_storyline(%{}, member)
    end

    test "create_private_storyline/1 adds the company patches and default flow", %{
      member: member,
      company_html_patch: patch
    } do
      assert {:ok, storyline} =
               Api.StorylineCreation.create_private_storyline(%{name: "some name"}, member)

      payloads_datas =
        Api.Patching.list_storyline_patches(storyline.id)
        |> Enum.map(fn patch -> patch.data end)

      assert patch.data in payloads_datas
    end
  end
end
