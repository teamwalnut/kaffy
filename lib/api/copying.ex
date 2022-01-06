defmodule Api.Copying do
  @moduledoc """
  Handles copying Screens/Storylines/Edits
  """
  alias Api.Annotations
  alias Api.Repo
  alias Api.Storylines.SmartObjects
  alias Api.Storylines.Storyline
  alias Ecto.Multi

  @doc """
  Creates a copy of a storyline with the following modifications:
  - Makes the storyline private
  - Makes the the owner to owner_id
  - Removes all previous collaborators
  - Deep copies all flows-->screens including edits
  - Deep copies all guides-->annotations
  - Prepends the word "Copy" before the storyline/screen name

  ## Examples

    iex> copy_storyline(owner_id, existing_storyline, actor)
    {:ok, storyline}

    iex> copy_storyline(owner_id, existing_storyline, actor)
    {:error, :unauthorized}
  """
  def copy_storyline(owner_id, %Storyline{} = storyline, actor) do
    authorization_relationship =
      if owner_id == actor.id do
        :presenter
      else
        :superadmin
      end

    with :ok <- Api.Authorizer.authorize(storyline, actor, authorization_relationship) do
      Multi.new()
      |> Multi.run(:storyline, fn _repo, %{} ->
        attrs =
          storyline
          |> Map.from_struct()
          |> Map.merge(%{name: "Copy of #{storyline.name}", is_public: false})
          |> Map.update(:demo_flags, %{}, fn cur_val -> Map.from_struct(cur_val) end)

        %Storyline{owner_id: owner_id}
        |> Storyline.create_changeset(attrs)
        |> Repo.insert()
      end)
      |> Multi.run(:patches, fn _repo, %{storyline: copied_storyline} ->
        patches = Api.Patching.list_storyline_patches(storyline.id)
        Api.Patching.add_patches(copied_storyline, patches, actor)
      end)
      |> Multi.run(:flows, fn _repo, %{storyline: copied_storyline} ->
        Api.Storylines.copy_flows(storyline.id, copied_storyline)
      end)
      |> Multi.run(:smart_objects, fn _repo,
                                      %{storyline: copied_storyline, flows: copied_flows} ->
        SmartObjects.Copying.copy_classes_and_remap_instances(
          storyline.id,
          copied_storyline,
          copied_flows
        )
      end)
      |> Multi.run(:guides, fn _repo, %{storyline: copied_storyline, flows: copied_flows} ->
        Annotations.copy_guides(storyline.id, copied_storyline, copied_flows)
      end)
      |> Multi.run(:settings, fn _repo, %{storyline: copied_storyline} ->
        Api.Settings.copy_storyline_settings(storyline.id, copied_storyline)
      end)
      |> Repo.transaction(timeout: 20_000)
      |> case do
        {:ok, %{storyline: copied_storyline}} ->
          {:ok, copied_storyline}

        {:error, _, :unauthorized, _} ->
          {:error, :unauthorized}
      end
    end
  end
end
