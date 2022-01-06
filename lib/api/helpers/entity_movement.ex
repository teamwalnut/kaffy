defmodule Api.EntityMovement do
  @moduledoc """
  A behaviour that knows how to move entities within the container/parent entity.
  """
  alias Api.Repo
  alias Ecto.{Adapters, Multi}

  @typedoc """
    An atom represting the entity type. E.g. Api.Annotations.Annotation
  """
  @type entity_type :: atom
  @typedoc """
    An struct of the entity. E.g. %Api.Annotations.Annotation{}
  """
  @type entity :: term

  @doc """
  Returns the entity's position field
  """
  @callback position_field_for_entity(entity) :: atom

  @doc """
  Returns the entity's position field
  """
  @callback position_field_for_entity_type(entity_type) :: atom

  @doc """
  Returns a list of all the passed entities siblings all_entity_siblings
  """
  @callback get_entities_to_reposition(entity) :: [entity]

  @doc """
  Returns the entity's reposition changeset function based on the passed entity
  """
  @callback reposition_changeset_func_for_entity(entity) :: function

  @doc """
  Returns the entity's reposition changeset function based on the passed entity_type
  """
  @callback reposition_changeset_func_for_entity_type(entity_type) :: function

  @doc """
  Repositions an entity inside a container/parent entity.

  ## Examples

    iex> reposition_entity(implementation, entity, new_entity_position)
    {:ok, ecto_multi_map}

    iex> reposition_entity(implementation, entity, new_entity_position)
    {:error, ecto_multi_map}

  """
  def reposition_entity(implementation, entity, new_entity_position) do
    position_field_for_entity = implementation.position_field_for_entity(entity)
    current_entity_position = entity |> Map.get(position_field_for_entity)

    repositioned_entities_changesets =
      build_reposition_entity_changesets(
        implementation,
        current_entity_position,
        new_entity_position,
        entity
      )

    if Enum.empty?(repositioned_entities_changesets) do
      entity_name = entity.__struct__ |> Module.split() |> List.last() |> String.downcase()
      {:ok, %{entity_name => entity}}
    else
      multi =
        Multi.new()
        |> Multi.run("deferred", fn _repo, _ ->
          Adapters.SQL.query!(Repo, entity.__struct__.defer_position_unique_constraint_query())
          {:ok, nil}
        end)

      repositioned_entities_changesets
      |> Enum.reduce(multi, fn changeset, multi_acc ->
        current_entity_position = changeset.changes |> Map.get(position_field_for_entity)
        Multi.update(multi_acc, Integer.to_string(current_entity_position), changeset)
      end)
      |> Repo.transaction()
    end
  end

  defp build_reposition_entity_changesets(
         _implementation,
         current_position,
         new_position,
         _entity
       )
       when current_position == new_position,
       do: []

  defp build_reposition_entity_changesets(
         implementation,
         current_position,
         new_position,
         entity
       )
       when current_position > new_position do
    position_field_for_entity = implementation.position_field_for_entity(entity)
    entities_to_reposition = implementation.get_entities_to_reposition(entity)
    changeset_func = implementation.reposition_changeset_func_for_entity(entity)

    entities_to_reposition
    |> Enum.filter(fn entity ->
      entity_position = entity |> Map.get(position_field_for_entity)
      entity_position >= new_position && entity_position <= current_position
    end)
    |> Enum.map(fn entity ->
      new_position =
        calc_new_entity_position(implementation, current_position, new_position, entity, 1)

      attrs = Map.put(%{}, position_field_for_entity, new_position)
      changeset_func.(entity, attrs)
    end)
  end

  defp build_reposition_entity_changesets(
         implementation,
         current_position,
         new_position,
         entity
       )
       when current_position < new_position do
    position_field_for_entity = implementation.position_field_for_entity(entity)

    entities_to_reposition = implementation.get_entities_to_reposition(entity)
    changeset_func = implementation.reposition_changeset_func_for_entity(entity)

    entities_to_reposition
    |> Enum.filter(fn entity ->
      entity_position = entity |> Map.get(position_field_for_entity)
      entity_position >= current_position && entity_position <= new_position
    end)
    |> Enum.map(fn entity ->
      new_position =
        calc_new_entity_position(implementation, current_position, new_position, entity, -1)

      attrs = Map.put(%{}, position_field_for_entity, new_position)
      changeset_func.(entity, attrs)
    end)
  end

  defp calc_new_entity_position(
         implementation,
         current_position,
         new_position,
         entity,
         position_to_add
       ) do
    position_field_for_entity = implementation.position_field_for_entity(entity)
    entity_position = entity |> Map.get(position_field_for_entity)

    if entity_position == current_position,
      do: new_position,
      else: entity_position + position_to_add
  end

  @doc """
  Repositions all the entities in order. Useful when an entity is deleted from a container/parent entity.

  ## Examples

      iex> compact_entities(implementation, entities, entities)
      {:ok, multi_map}

      iex> compact_entities(implementation, entities, entity_type)
      {:error, error}

  """
  def compact_entities(implementation, entities, entity_type) do
    position_field_for_entity = implementation.position_field_for_entity_type(entity_type)

    multi =
      Multi.new()
      |> Multi.run("deferred", fn _repo, _ ->
        Adapters.SQL.query!(
          Repo,
          entity_type.defer_position_unique_constraint_query()
        )

        {:ok, nil}
      end)

    changesets = build_compact_entities_changesets(implementation, entities, entity_type)

    multi_result =
      changesets
      |> Enum.reduce(multi, fn changeset, multi_acc ->
        current_entity_position = changeset.changes |> Map.get(position_field_for_entity)
        Multi.update(multi_acc, Integer.to_string(current_entity_position), changeset)
      end)
      |> Repo.transaction()

    case multi_result do
      {:ok, _} -> {:ok, "entity compacted successfully"}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  defp build_compact_entities_changesets(implementation, entities, entity_type) do
    position_field_for_entity = implementation.position_field_for_entity_type(entity_type)

    index_basis = entity_type.position_index_basis()

    entities
    |> Enum.with_index(index_basis)
    |> Enum.reject(fn {entity, index} ->
      entity_position = entity |> Map.get(position_field_for_entity)
      entity_position == index
    end)
    |> Enum.map(fn {entity, index} ->
      attrs = Map.put(%{}, position_field_for_entity, index)
      implementation.reposition_changeset_func_for_entity_type(entity_type).(entity, attrs)
    end)
  end
end
