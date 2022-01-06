defmodule Api.StorylineCreationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.StorylineCreation` context.
  """
  alias Api.StorylineCreation

  def unique_storyline_creation_name, do: "#{Api.FixtureSequence.next("storyline_")}"

  def private_storyline_creation_fixture(owner, attrs \\ %{}) do
    default_attrs = %{
      last_edited: "2010-04-17T14:00:00Z"
    }

    attrs = Enum.into(attrs, default_attrs)

    {:ok, storyline} = StorylineCreation.create_private_storyline(attrs, owner)

    storyline
  end

  def public_storyline_creation_fixture(owner, attrs \\ %{}) do
    default_attrs = %{
      last_edited: "2010-04-17T14:00:00Z",
      name: unique_storyline_creation_name(),
      is_shared: false
    }

    attrs = Enum.into(attrs, default_attrs)

    {:ok, storyline} = StorylineCreation.create_public_storyline(attrs, owner)

    storyline
  end

  def setup_public_storyline_creation(%{member: member}) do
    attrs = Enum.into(%{}, %{name: unique_storyline_creation_name(), is_public: true})

    {:ok, storyline} = StorylineCreation.create_public_storyline(attrs, member)
    {:ok, public_storyline: storyline}
  end
end
