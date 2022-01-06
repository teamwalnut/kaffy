defmodule Api.Storylines.ScreenGroupingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Storylines.ScreenGrouping` context.
  """

  alias Api.Storylines

  def unique_flow_name, do: Api.FixtureSequence.next("flow_")

  def default_flow_fixture(storyline_id) do
    Storylines.get_default_flow(storyline_id)
  end

  def flow_fixture(storyline_id, attrs \\ %{}) do
    default_attrs = %{
      name: unique_flow_name()
    }

    attrs = Enum.into(attrs, default_attrs)

    {:ok, flow} = Storylines.ScreenGrouping.create_flow(storyline_id, attrs)

    flow
  end

  def get_default_flow(%{public_storyline: public_storyline}) do
    {:ok, default_flow: default_flow_fixture(public_storyline.id)}
  end

  def setup_flow(%{public_storyline: public_storyline}, attrs \\ %{}) do
    {:ok, flow: flow_fixture(public_storyline.id, attrs)}
  end

  def setup_multiple_flows(%{public_storyline: public_storyline}) do
    {:ok,
     flows: [
       flow_fixture(public_storyline.id),
       flow_fixture(public_storyline.id),
       flow_fixture(public_storyline.id)
     ]}
  end

  def flow_screen_fixture(storyline, flow) do
    Storylines.add_screen_to_flow(storyline, flow)
  end
end
