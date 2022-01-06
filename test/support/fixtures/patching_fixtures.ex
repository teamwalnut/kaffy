defmodule Api.PatchingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Patching` context.
  """

  alias Api.Patching

  def unique_html_patch,
    do: %{
      position: Ecto.Enum.values(Patching.HtmlPatch, :position) |> Enum.random(),
      css_selector: "#{Api.FixtureSequence.next(".selector_")}",
      html: "<im>#{Api.FixtureSequence.next("html")}</im>",
      targetUrlGlob: "#{Api.FixtureSequence.next("blob")}",
      __type__: :html_patch
    }

  def company_patch_fixture(company, patch_data, actor) do
    {:ok, patch} = Patching.add_company_patch(company.id, patch_data, "test", actor)
    patch
  end

  def storyline_patch_fixture(storyline, patch_data) do
    storyline = storyline |> Api.Repo.preload(owner: [:user, :company])

    {:ok, patch} = Patching.add_storyline_patch(storyline.id, patch_data, "test", storyline.owner)
    patch
  end

  def setup_company_html_patch(%{company: company, member: member}) do
    {:ok, company_html_patch: company_patch_fixture(company, unique_html_patch(), member)}
  end

  def setup_storyline_html_patch(%{public_storyline: storyline}) do
    {:ok, storyline_html_patch: storyline_patch_fixture(storyline, unique_html_patch())}
  end
end
