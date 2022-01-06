defmodule Api.Annotations do
  @moduledoc """
  The Annotations context, allows you to add a layer for demos with guides.
  A Guide is a collection of annotations ordered linearly per a Storyline.
  An Annotation is a piece of information anchored to an element in a screen, or the whole screen.
  """
  @behaviour Api.EntityMovement

  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Storylines.Demos.Demo
  alias Api.Storylines.Demos.DemoVersion
  alias Api.Storylines.Screen
  alias Api.Storylines.Storyline
  alias Api.Annotations.{Annotation, Copying, Guide}
  alias Ecto.{Adapters, Multi}

  defdelegate copy_guides(from_screen_id, target_screen_id, target_guide_id), to: Copying

  @doc """
  Returns all guides for a storyline ordered by priority

  ## Examples

      iex> list_guides(storyline_id)
      [%Guide{}]
  """
  def list_guides(storyline_id) do
    storyline_id |> Guide.list_query() |> Repo.all()
  end

  @doc """
  Gets a single guide by its ID, throws if cannot find one.

  ## Examples

      iex> get_guide("uuid")
      %Guide{}
  """
  def get_guide!(guide_id) do
    Repo.get!(Guide, guide_id)
  end

  @doc """
  Creates a guide for storyline.

  ## Examples

      iex> create_guide(storyline_id, valid_attrs, actor)
      {:ok, %Guide{}}

      iex> create_guide(storyline_id, invalid_attrs, bad_actor)
      {:error, :unauthorized}

      iex> create_guide(storyline_id, invalid_attrs, actor)
      {:error, %Ecto.Changeset{}}

  """
  def create_guide(storyline_id, attrs, actor) do
    storyline = Storyline |> Repo.get!(storyline_id)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      max_priority = get_guide_max_priority(storyline_id)
      new_priority = if max_priority == nil, do: 0, else: max_priority + 1
      attrs = attrs |> Map.put(:priority, new_priority)

      %Guide{storyline_id: storyline_id}
      |> Guide.create_changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Updates a guide name

  ## Examples

        iex> rename_guide(guide, "valid_name", actor)
        {:ok, %Guide{}}

        iex> rename_guide(guide, "valid_name", bad_actor)
        {:error, :unauthorized}

        iex> rename_guide(guide, nil, actor)
        {:error, %Ecto.Changeset{}}
  """
  def rename_guide(%Guide{} = guide, name, actor) do
    storyline = get_related_storyline(guide)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      guide
      |> Guide.rename_changeset(%{name: name})
      |> Repo.update()
    end
  end

  @doc """
  Deletes a guide.

  ## Examples

      iex> delete_guide(guide, actor)
      {:ok, multi_map}

      iex> delete_guide(guide, bad_actor)
      {:error, :unauthorized}

      iex> delete_guide(guide, actor)
      {:error, multi_map}

  """
  def delete_guide(%Guide{} = guide, actor) do
    storyline = get_related_storyline(guide)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      Multi.new()
      |> Multi.run(:delete_guide, fn _repo, _ ->
        guide |> Guide.delete_changeset() |> Repo.delete()
      end)
      |> Multi.run(:compact_guides, fn _repo, _ ->
        compact_guides(guide.storyline_id)
      end)
      |> Repo.transaction()
    end
  end

  defp compact_guides(storyline_id) do
    guides = list_guides(storyline_id)
    Api.EntityMovement.compact_entities(__MODULE__, guides, Guide)
  end

  @doc """
  Repositions a guide inside a storyline.

  ## Examples

    iex> reposition_guide(guide_id, new_priority, actor)
    {:ok, %Guide{}}

    iex> reposition_guide(guide_id, new_priority, actor)
    {:error, %Ecto.Changeset{}}

    iex> reposition_guide(guide_id, new_priority, bad_actor)
    {:error, :unauthorized}

    iex> reposition_guide(guide_id, new_priority, actor)
    {:error, "The new position is out of bounds"}
  """
  def reposition_guide(guide_id, new_priority, actor) do
    guide = get_guide!(guide_id)
    storyline = get_related_storyline(guide)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      max_priority = get_guide_max_priority(guide.storyline_id)

      if new_priority > max_priority do
        {:error, "The new priority position is out of bounds"}
      else
        Api.EntityMovement.reposition_entity(__MODULE__, guide, new_priority)
      end
    end
  end

  @doc """
  Gets an annotation

  Raises `Ecto.NoResultsError` if the Annotation does not exist.

  ## Examples

      iex> get_annotation!(id)
      %Annotation{}

      iex> get_annotation!(incorrect_id)
      {:error, %Ecto.Changeset{}}

  """
  def get_annotation!(id), do: Repo.get!(Annotation, id)

  @doc """
  Adds a modal or point Annotation to a Guide based on the passed attributes and the passed kind.

  ## Examples

      iex> add_annotation_to_guide(guide_id, %{field: value}, :point, actor)
      {:ok, %Annotation{}}

      iex> add_annotation_to_guide(guide_id, %{field: value}, :point, actor)
      {:ok, multi_map}

      iex> add_annotation_to_guide(guide_id, %{field: bad_value}, :point, actor)
      {:error, %Ecto.Changeset{}}

      iex> add_annotation_to_guide(guide_id, %{field: value}, :modal, actor)
      {:ok, %Annotation{}}

      iex> add_annotation_to_guide(guide_id, %{field: value}, :modal, actor)
      {:ok, multi_map}

      iex> add_annotation_to_guide(guide_id, %{field: bad_value}, :modal, actor)
      {:error, %Ecto.Changeset{}}
  """

  def add_annotation_to_guide(guide_id, attrs, kind, actor) do
    guide = Guide |> Repo.get!(guide_id) |> Repo.preload(:storyline)

    with :ok <- Api.Authorizer.authorize(guide.storyline, actor, :presenter) do
      if attrs[:step] do
        add_annotation_to_guide_at_step(guide_id, attrs, kind)
      else
        max_step = get_guide_next_step(guide_id)
        attrs = attrs |> Map.put(:step, max_step)

        %Annotation{guide_id: guide_id, kind: kind}
        |> Annotation.create_changeset(attrs, kind)
        |> Repo.insert()
      end
    end
  end

  defp add_annotation_to_guide_at_step(guide_id, attrs, kind) do
    # first build changeset for creating the new annotation in the correct step
    annotation_creation_changeset =
      %Annotation{guide_id: guide_id, kind: kind}
      |> Annotation.create_between_steps_changeset(attrs, kind)

    # next, build changesets for subsequent annotations to move 1 step foward
    subsequent_annotations_reposition_changesets =
      build_annotations_reposition_changesets(guide_id, attrs[:step])

    # next, create a multi call that will start with deferring the step unique constraint
    multi =
      Multi.new()
      |> Multi.run("deferred", fn _repo, _ ->
        Adapters.SQL.query!(Repo, Annotation.defer_position_unique_constraint_query())
        {:ok, nil}
      end)

    multi = Multi.insert(multi, "create_annotation", annotation_creation_changeset)

    # itereate over changesets and create a Multi.update call for each one
    subsequent_annotations_reposition_changesets
    |> Enum.reduce(multi, fn changeset, multi_acc ->
      Multi.update(multi_acc, Integer.to_string(changeset.changes.step), changeset)
    end)
    |> Repo.transaction()
  end

  defp build_annotations_reposition_changesets(guide_id, new_annotations_step) do
    annotations_to_reposition =
      guide_id
      |> Annotation.all_next_annotations_query(new_annotations_step)
      |> Repo.all()

    changeset_func = reposition_changeset_func_for_entity_type(Annotation)

    annotations_to_reposition
    |> Enum.map(fn annotation ->
      new_step = annotation.step + 1
      changeset_func.(annotation, %{step: new_step})
    end)
  end

  @doc """
  Updates an Annotation.

  ## Examples

      iex> update_annotation(annotation, %{field: new_value}, actor)
      {:ok, %Annotation{}}

      iex> update_annotation(annotation, %{field: new_value}, bad_actor)
      {:ok, :unauthorized}

      iex> update_annotation(annotation, %{field: bad_value}, actor)
      {:error, %Ecto.Changeset{}}

  """
  def update_annotation(%Annotation{} = annotation, attrs, actor) do
    storyline = get_related_storyline(annotation)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      annotation
      |> Annotation.update_changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Deletes an Annotation.

  ## Examples

      iex> delete_annotation(annotation, actor)
      {:ok, %Annotation{}}

      iex> delete_annotation(annotation, bad_actor)
      {:error, :unauthorized}

      iex> delete_annotation(annotation, actor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_annotation(%Annotation{} = annotation, actor) do
    annotation = annotation |> Repo.preload(guide: [:annotations])
    guide = annotation.guide

    storyline = get_related_storyline(annotation)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      result =
        Multi.new()
        |> Multi.delete(:annotation, annotation |> Annotation.delete_changeset())
        |> Multi.run(:compact_guide, fn _repo, _ ->
          compact_guide(guide.id)
        end)
        |> Repo.transaction()

      case result do
        {:ok, %{annotation: annotation}} -> {:ok, annotation}
        {:error, error} -> {:error, error}
      end
    end
  end

  defp get_related_storyline(%Guide{} = guide) do
    guide =
      guide
      |> Repo.preload(storyline: [], demo_version: [demo: [storyline: []]])

    case guide do
      %Guide{storyline: %Storyline{} = storyline} ->
        storyline

      %Guide{demo_version: %DemoVersion{demo: %Demo{storyline: %Storyline{} = storyline}}} ->
        storyline
    end
  end

  defp get_related_storyline(%Annotation{} = annotation) do
    annotation = annotation |> Repo.preload(screen: [storyline: []])

    case annotation do
      %Annotation{screen: %Screen{storyline: %Storyline{} = storyline}} ->
        storyline

      %Annotation{guide: %Guide{} = guide} ->
        get_related_storyline(guide)
    end
  end

  @doc """
  Repositions all the annotations in order.
  Useful when an annotations is deleted from a guide,
  or when a screen is deleted with related annotations.

  ## Examples

      iex> compact_guide(guide_id)
      {:ok, "entity compacted successfully"}

      iex> compact_guide(guide_id)
      {:error, error}

  """
  def compact_guide(guide_id) do
    guide = get_guide_with_annotations!(guide_id)

    Api.EntityMovement.compact_entities(__MODULE__, guide.annotations, Annotation)
  end

  @doc """
  Deletes all annotations in a given screen

  ## Examples

      iex> delete_annotations_in_screen(screen_id)
      [%Annotation{}, ...]

  """
  def delete_annotations_in_screen(screen_id) do
    Annotation.annotations_in_screen_query(screen_id) |> Repo.delete_all()
  end

  @doc """
  Repositions an annotation (step) inside a guide.

  ## Examples

    iex> reposition_annotation(annotation_id, new_step_position, actor)
    {:ok, %Annotation{}}

    iex> reposition_annotation(annotation_id, new_step_position, actor)
    {:error, %Ecto.Changeset{}}

    iex> reposition_annotation(annotation_id, new_step_position, actor)
    {:error, "The new step position is out of bounds"}
  """
  def reposition_annotation(annotation_id, new_step_position, actor) do
    annotation = Repo.get(Annotation, annotation_id) |> Repo.preload(:guide)
    storyline = get_related_storyline(annotation)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      max_step = get_guide_annotations_max_step(annotation.guide.id)

      if new_step_position > max_step do
        {:error, "The new step position is out of bounds"}
      else
        Api.EntityMovement.reposition_entity(__MODULE__, annotation, new_step_position)
      end
    end
  end

  @impl Api.EntityMovement
  def position_field_for_entity(%Annotation{}), do: :step

  @impl Api.EntityMovement
  def position_field_for_entity(%Guide{}), do: :priority

  @impl Api.EntityMovement
  def position_field_for_entity_type(Annotation), do: :step

  @impl Api.EntityMovement
  def position_field_for_entity_type(Guide), do: :priority

  @impl Api.EntityMovement
  def get_entities_to_reposition(%Annotation{} = annotation) do
    annotation.guide.id |> Annotation.all_guide_annotations_query() |> Repo.all()
  end

  @impl Api.EntityMovement
  def get_entities_to_reposition(%Guide{} = guide), do: list_guides(guide.storyline_id)

  @impl Api.EntityMovement
  def reposition_changeset_func_for_entity(%Annotation{}),
    do: reposition_changeset_func_for_entity_type(Annotation)

  @impl Api.EntityMovement
  def reposition_changeset_func_for_entity(%Guide{}),
    do: reposition_changeset_func_for_entity_type(Guide)

  @impl Api.EntityMovement
  def reposition_changeset_func_for_entity_type(Annotation),
    do: &Annotation.reposition_changeset/2

  @impl Api.EntityMovement
  def reposition_changeset_func_for_entity_type(Guide), do: &Guide.reposition_changeset/2

  defp get_guide_with_annotations!(id) do
    get_guide!(id) |> Repo.preload(annotations: Annotation.all_annotations_query())
  end

  defp get_guide_next_step(guide_id) do
    max = get_guide_annotations_max_step(guide_id)
    if max, do: max + 1, else: 0
  end

  defp get_guide_annotations_max_step(guide_id) do
    guide_id |> Annotation.all_guide_annotations_query() |> Repo.aggregate(:max, :step)
  end

  defp get_guide_max_priority(storyline_id),
    do: storyline_id |> Guide.list_query() |> Repo.aggregate(:max, :priority)
end
