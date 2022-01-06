defmodule Api.StorylinesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Storylines` context.
  """

  alias Api.StorylineCreation
  alias Api.Storylines

  def unique_storyline_name, do: Api.FixtureSequence.next("storyline_")
  def unique_screen_name, do: Api.FixtureSequence.next("screen_")
  # ["00", "01", "02", "03", ..., "59"]
  @str_double_lead_range Enum.map(0..59, &(Integer.to_string(&1) |> String.pad_leading(2, "0")))

  defp update_last_edited(storyline, last_edited) do
    import Ecto.Query
    alias Api.Repo
    alias Api.Storylines.Storyline

    storyline_id = storyline.id

    from(storyline in Storyline, where: storyline.id == ^storyline_id)
    |> Repo.update_all(set: [last_edited: last_edited])

    Repo.get(Storyline, storyline.id)
  end

  def private_storyline_fixture(owner, attrs \\ %{}) do
    default_attrs = %{
      last_edited:
        "2010-04-17T14:00:" <>
          Api.FixtureSequence.next(:storyline_fixture, @str_double_lead_range) <> "Z"
    }

    attrs = Enum.into(attrs, default_attrs)
    {:ok, storyline} = StorylineCreation.create_private_storyline(attrs, owner)

    storyline
  end

  def public_storyline_fixture(owner, attrs \\ %{}) do
    default_attrs = %{
      name: unique_storyline_name(),
      last_edited:
        "2010-04-17T14:00:" <>
          Api.FixtureSequence.next(:storyline_fixture, @str_double_lead_range) <> "Z"
    }

    attrs = Enum.into(attrs, default_attrs)

    {:ok, storyline} = StorylineCreation.create_public_storyline(attrs, owner)

    storyline
  end

  def empty_storyline_fixture(owner, attrs \\ %{}) do
    default_attrs = %{
      last_edited:
        "2010-04-17T14:00:" <>
          Api.FixtureSequence.next(:storyline_fixture, @str_double_lead_range) <> "Z",
      name: unique_storyline_name()
    }

    attrs = Enum.into(attrs, default_attrs)

    {:ok, storyline} =
      %Storylines.Storyline{owner_id: owner.id}
      |> Storylines.Storyline.create_changeset(attrs)
      |> Api.Repo.insert()

    storyline
  end

  def screen_fixture(storyline, attrs \\ %{}) do
    default_attrs = %{
      screenshot_image_uri: "some image_uri",
      # make sure the last edited is not exactly the same, so sorting works
      last_edited:
        "2010-04-17T14:00:" <>
          Api.FixtureSequence.next(:screen_fixture, @str_double_lead_range) <> "Z",
      name: attrs[:name] || Api.FixtureSequence.next("some name "),
      url: "some url",
      s3_object_name: "some_object_name",
      original_dimensions: %{height: 761, width: 1600},
      asset_manifest: %{}
    }

    attrs = Enum.into(attrs, default_attrs) |> Enum.into(%{name: unique_screen_name()})

    {:ok, screen} = Storylines.add_screen_to_default_flow_unauthorized(storyline, attrs)

    screen
  end

  def screen_in_flow_fixture(storyline, flow, attrs \\ %{}) do
    default_attrs = %{
      screenshot_image_uri: "some image_uri",
      last_edited:
        "2010-04-17T14:00:" <>
          Api.FixtureSequence.next(:screen_fixture, @str_double_lead_range) <> "Z",
      name: attrs[:name] || Api.FixtureSequence.next("some name "),
      url: "some url",
      s3_object_name: "some_object_name",
      original_dimensions: %{height: 761, width: 1600}
    }

    attrs = Enum.into(attrs, default_attrs) |> Enum.into(%{name: unique_screen_name()})

    {:ok, screen} = Storylines.add_screen_to_flow(storyline, flow, attrs)

    screen
  end

  def setup_public_storyline(%{member: member}) do
    attrs = %{
      name: unique_storyline_name(),
      is_public: true,
      # NOTE(Jaap)
      # this happens before the fixture sequence is reset, this needs to be earlier than the
      # fixtures, so here we set it to one second before the storyline fixture
      last_edited: "2010-04-17T13:59:59Z"
    }

    {:ok, storyline} = StorylineCreation.create_public_storyline(attrs, member)
    {:ok, public_storyline: storyline}
  end

  def setup_collaborator(%{public_storyline: storyline, company: company}) do
    user = Api.AccountsFixtures.user_fixture()
    {:ok, member} = Api.Companies.add_member(user.id, company)
    {:ok, collab} = Storylines.add_collaborator(storyline, member.id, member)
    {:ok, collaborator: collab}
  end

  def setup_screen(%{public_storyline: storyline}) do
    screen = screen_fixture(storyline)
    # NOTE(Jaap)
    # make sure the last edited property of the storyline is retained (and not updated
    # by creating this new screen)
    # The fixtures have a fixed last_edited datetime
    storyline = update_last_edited(storyline, storyline.last_edited)
    {:ok, screen: screen, public_storyline: storyline}
  end

  def setup_multiple_screens(%{public_storyline: storyline}) do
    # note(itay):
    # I've set it up this way to ensure the order of execution, so the first screen will be the start screen
    screens =
      [screen_fixture(storyline)] ++
        [screen_fixture(storyline)] ++
        [screen_fixture(storyline)] ++ [screen_fixture(storyline)] ++ [screen_fixture(storyline)]

    storyline = storyline |> Api.Repo.reload()

    {:ok, screens: screens, public_storyline: storyline}
  end
end
