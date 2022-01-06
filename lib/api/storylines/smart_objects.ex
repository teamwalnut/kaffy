defmodule Api.Storylines.SmartObjects do
  @moduledoc """
  This module handles Smart Objects, primarily Classes.

  A Smart Object Class represent a collection of edits, that can later be
  instantiated into an object on a Screen. We call those objects Instances.

  When a Smart Object Class is updated, all its instances are updated as well.
  """

  alias Api.Repo
  alias Api.Storylines.Editing.Edit
  alias Api.Storylines.Screen
  alias Api.Storylines.Screens
  alias Api.Storylines.SmartObjects.Class
  alias Api.Storylines.SmartObjects.Instance
  alias Ecto.Multi

  @doc """
  Get a Smart Object Class by ID.

  Raises `Ecto.NoResultsError` if the SmartObjects.Class does not exist.

  ## Examples

      iex> get_class!(existing_class_id)
      %Class{}

      iex> get_class!(inexistent_class_id)
      ** (Ecto.NoResultsError)
  """
  def get_class!(class_id),
    do: Repo.get!(Class, class_id)

  @doc """
  Lists all the Smart Object Classes that belong to a Storyline.
  """
  def list_classes(storyline_id),
    do: {:ok, Class.list_not_archived_query(storyline_id) |> Repo.all()}

  @doc """
  Creates a Smart Object Class.
  """
  def create_class(%Class{} = smart_object_class, actor) do
    class = Repo.preload(smart_object_class, storyline: [])

    with :ok <- Api.Authorizer.authorize(class.storyline, actor, :presenter) do
      smart_object_class
      |> Class.create_changeset()
      |> Repo.insert()
    end
  end

  @doc """
  Updates the name of a given Smart Object Class.
  """
  def rename_class(class_id, name, actor) do
    class = get_class!(class_id)
    class = class |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(class.storyline, actor, :presenter) do
      class
      |> Class.update_changeset(%{name: name})
      |> Repo.update()
    end
  end

  @doc """
  Archive smart object class
  """
  def archive_class(class_id, actor) do
    class = get_class!(class_id)
    class = class |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(class.storyline, actor, :presenter) do
      screens = Screens.get_all_with_instances(class.storyline_id)

      result =
        Multi.new()
        |> delete_all_instances(screens, class_id, actor)
        |> Multi.update(:archived_class, Class.archive_changeset(class))
        |> Repo.transaction()

      case result do
        {:ok, %{archived_class: archived_class}} -> {:ok, archived_class}
        {:error, error} -> {:error, error}
      end
    end
  end

  @doc """
  Updates a Smart Object Class and updates all of its instances.

  Raises if the Class can't be updated, or if any of the relevant Instances
  can't be updated.
  """
  def update_class_and_its_instances(%Class{} = smart_object_class, attrs, actor) do
    smart_object_class = Repo.preload(smart_object_class, storyline: [])

    with :ok <- Api.Authorizer.authorize(smart_object_class.storyline, actor, :presenter) do
      updated_class =
        smart_object_class
        |> Class.update_changeset(attrs)
        |> Repo.update!()

      Screen.by_storyline_id_query(updated_class.storyline_id)
      |> Repo.all()
      |> Enum.filter(fn screen ->
        screen.smart_object_instances
        |> Enum.any?(fn instance ->
          instance.class_id == updated_class.id
        end)
      end)
      |> Enum.map(fn screen ->
        smart_object_instances =
          screen.smart_object_instances
          |> update_instances_edits_from_class(updated_class)
          |> Instance.to_attributes()

        Screen.update_changeset(screen, %{smart_object_instances: smart_object_instances})
      end)
      |> Enum.each(fn change -> Repo.update!(change) end)

      {:ok, updated_class}
    end
  end

  defp update_instances_edits_from_class(smart_object_instances, %Class{} = class) do
    smart_object_instances
    |> Enum.map(fn instance ->
      if instance |> Instance.of_class?(class) && !instance.detached do
        new_overrides =
          instance.edits_overrides
          |> Enum.filter(fn override -> !Enum.member?(class.edits, override) end)

        %{instance | edits: class.edits, edits_overrides: new_overrides}
      else
        instance
      end
    end)
  end

  @doc """
  Update the Smart Object Instances of a given screen.
  """
  def update_instances_in_screen(screen_id, instances, actor) do
    with {:ok, screen} <- Screens.get(screen_id),
         screen <- Repo.preload(screen, storyline: []),
         :ok <- Api.Authorizer.authorize(screen.storyline, actor, :presenter),
         {:ok, classes} <- list_classes(screen.storyline_id),
         {:ok, screen} <-
           Screens.update_smart_object_instances(
             screen,
             instances
             |> Enum.map(fn instance ->
               class =
                 classes
                 |> Enum.find(fn class -> instance |> Instance.of_class?(class) end)
                 |> Edit.to_attributes()

               %{
                 screen_id: screen.id,
                 storyline_id: screen.storyline_id,
                 class_id: class["id"],
                 edits: class["edits"],
                 edits_overrides: Map.get(instance, :edits_overrides, []),
                 css_selector: Map.get(instance, :override_css_selector, class["css_selector"]),
                 frame_selectors:
                   Map.get(instance, :override_frame_selectors, class["frame_selectors"]),
                 dom_selector: Map.get(instance, :override_dom_selector, class["dom_selector"])
               }
             end)
           ) do
      {:ok, screen.smart_object_instances}
    end
  end

  @doc """
  Lists the Smart Object Instances for a given Screen.
  """
  def list_instances(screen_id) do
    {:ok, screen} = Screens.get(screen_id)

    {:ok, screen.smart_object_instances || []}
  end

  @doc """
  Delete all instances of a given class in screens
  """
  def delete_all_instances(multi, screens, class_id, actor) do
    new_screens =
      Enum.map(screens, fn s ->
        %{
          s
          | smart_object_instances:
              remove_instances_with_class_id(s.smart_object_instances, class_id)
        }
      end)

    Enum.reduce(new_screens, multi, fn screen, multi ->
      Multi.run(multi, "deleting_instances_on#{screen.id}", fn _, _ ->
        update_instances_in_screen(screen.id, screen.smart_object_instances, actor)
      end)
    end)
  end

  defp remove_instances_with_class_id(instances, class_id) do
    Enum.filter(instances, &(&1.class_id != class_id))
  end

  @doc """
  Detach all the Smart Object Instances of a given Screen.
  Raises if the Screen can't be updated.
  """
  def detach_instance(screen_id, instance_id, actor) do
    with {:ok, screen} <- Screens.get(screen_id),
         screen <- screen |> Repo.preload(storyline: []),
         :ok <- Api.Authorizer.authorize(screen.storyline, actor, :presenter) do
      screen =
        Screen.update_changeset(screen, %{
          smart_object_instances:
            screen.smart_object_instances
            |> Instance.to_attributes()
            |> Enum.map(fn instance ->
              if instance["id"] == instance_id do
                %{instance | "detached" => true}
              else
                instance
              end
            end)
        })
        |> Repo.update!()

      {:ok, screen.smart_object_instances}
    end
  end

  @doc """
  Deletes class and instances edits that are related to given screens.
  Useful when a screen is deleted.

  ## Examples

      iex> compact_class(%Class{}, %Screen{}, %Member{})
      {:ok, %Class{}}

  """
  def compact_class_and_its_instances(class, screens, actor) do
    new_class = convert_edits(class, :edits)
    screen_ids = screens |> Enum.map(& &1.id)

    new_class_edits =
      new_class.edits
      |> Enum.filter(&(!Edit.linked_to_screen_ids?(&1, screen_ids)))

    {:ok, updated_class} =
      update_class_and_its_instances(
        class,
        %{edits: new_class_edits},
        actor
      )

    {:ok, updated_class}
  end

  @doc """
  Convert smart object :edits or :edits_overrides
  """
  def convert_edits(edit_obj, key) do
    edit_obj
    |> Map.update!(key, fn edits ->
      case edits do
        nil -> []
        _ -> edits |> Enum.map(&convert_to_edit(&1))
      end
    end)
  end

  def convert_to_edit(edit_attributes) do
    edit_attributes = edit_attributes |> Edit.to_attributes()

    kind =
      case is_atom(edit_attributes["kind"]) do
        true -> edit_attributes["kind"]
        false -> edit_attributes["kind"] |> String.to_existing_atom()
      end

    Ecto.Changeset.apply_action!(
      Edit.update_changeset(
        %Edit{
          id: Ecto.UUID.generate(),
          kind: kind
        },
        edit_attributes
      ),
      :update
    )
  end
end
