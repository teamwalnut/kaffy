defmodule Api.DemosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Demos` context.
  """

  alias Api.Repo
  alias Api.Storylines.Demos.{Demo, DemoVersion}

  def unique_demo_name, do: "demo_#{System.unique_integer()}"

  def demo_version_fixture(creator, attrs \\ %{}) do
    {:ok, demo_version} =
      %DemoVersion{created_by_id: creator.id}
      |> DemoVersion.changeset(attrs)
      |> Repo.insert()

    demo_version
  end

  def demo_fixture(storyline, creator, attrs \\ %{}) do
    demo_attrs = %{
      name: unique_demo_name()
    }

    attrs = Enum.into(attrs, demo_attrs)

    {:ok, demo_version} =
      %DemoVersion{created_by_id: creator.id, start_screen_id: storyline.start_screen_id}
      |> DemoVersion.changeset(%{})
      |> Repo.insert()

    {:ok, demo} =
      %Demo{storyline_id: storyline.id, active_version_id: demo_version.id}
      |> Demo.changeset(attrs)
      |> Repo.insert()

    %{active_demo_version: demo_version, demo: demo}
  end

  def setup_demo(%{public_storyline: public_storyline, member: member}) do
    %{active_demo_version: active_demo_version, demo: demo} =
      demo_fixture(public_storyline, member)

    {:ok, demo: demo, active_demo_version: active_demo_version}
  end
end
