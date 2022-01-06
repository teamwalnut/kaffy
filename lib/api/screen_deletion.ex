defmodule Api.ScreenDeletion do
  @moduledoc """
  Handles screen deletion
  """
  require Logger
  alias Api.Annotations
  alias Api.Storylines

  alias Api.Storylines.{Screen, SmartObjects, Storyline}

  alias Ecto.Multi

  @doc """
  Deletes a screen, If you're trying to delete a start screen and there are other screens,
  we set the start screen to be another screen.
  If there are no other screens, we delete the start_screen f_key

  ## Examples

      iex> delete_screen(screen, actor)
      {:ok, %Screen{}}

      iex> delete_screen(screen, actor)
      {:error, %Ecto.Changeset{}}

      iex> delete_screen(screen, actor)
      {:error, :unauthorized}

  """
  def delete_screen(%Screen{} = screen, actor) do
    screen = screen |> Api.Repo.preload(guides: [], storyline: [:smart_object_classes])

    with :ok <- Api.Authorizer.authorize(screen.storyline, actor, :presenter) do
      multi =
        Multi.new()
        |> Multi.run(:delete_screen, fn _repo, _ ->
          Storylines.delete_screen(screen)
        end)

      multi =
        screen.guides
        |> Enum.reduce(multi, fn guide, multi ->
          multi
          |> Multi.run("compound_guide_#{guide.id}", fn _repo, _changes_so_far ->
            # compact each guide that this screen is associated with
            Annotations.compact_guide(guide.id)
          end)
        end)

      result =
        screen.storyline.smart_object_classes
        |> Enum.reduce(multi, fn class, multi ->
          multi
          |> Multi.run("compound_class_#{class.id}", fn _repo, _changes_so_far ->
            SmartObjects.compact_class_and_its_instances(class, [screen], actor)
          end)
        end)
        |> Api.Repo.transaction()

      case result do
        {:ok, %{delete_screen: %{screen: screen}}} ->
          {:ok, %{screen: screen}}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  @doc """
  Deletes multiple screens in a storyline, If one of these screens is a start screen and there are
  other screens, we set the start screen to be another screen.
  If there are no other screens, we delete the start_screen f_key

  ## Examples

      iex> delete_screens(storyline, screen_ids, actor)
      {:ok, [%Screen{}, ...]}

      iex> delete_screens(storyline, screen_ids, actor)
      {:error, :unauthorized}
  """
  def delete_screens(%Storyline{} = storyline, screen_ids, actor) do
    storyline = Api.Repo.preload(storyline, [:screens, :smart_object_classes])

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      screens =
        storyline.screens
        |> Enum.filter(&(&1.id in screen_ids))
        |> Api.Repo.preload(:guides)

      multi =
        Multi.new()
        |> Multi.run(:delete_screens, fn _repo, _ ->
          Storylines.delete_screens(storyline, screens)
        end)

      multi =
        screens
        |> Enum.flat_map(& &1.guides)
        |> Enum.reduce(multi, fn guide, multi ->
          multi
          |> Multi.run("compound_guide_#{guide.id}", fn _repo, _changes_so_far ->
            # compact each guide that this screen is associated with
            Annotations.compact_guide(guide.id)
          end)
        end)

      result =
        storyline.smart_object_classes
        |> Enum.reduce(multi, fn class, multi ->
          multi
          |> Multi.run("compound_class_#{class.id}", fn _repo, _changes_so_far ->
            SmartObjects.compact_class_and_its_instances(class, screens, actor)
          end)
        end)
        |> Api.Repo.transaction()

      case result do
        {:ok, %{delete_screens: screens}} ->
          {:ok, screens}

        {:error, error} ->
          {:error, error}
      end
    end
  end
end
