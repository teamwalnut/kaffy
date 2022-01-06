defmodule Api.Storylines.ScreenGrouping do
  @moduledoc """
  ScreenGrouping handles everything related to grouping screens inside a storyline,
  groupings are handled by the Flow and FlowScreen entities,
  Flow defines the name and if it's the default flow of the storyline
  and FlowScreen defines which screen belongs to which flow and in which position iniside the flow.
  """
  @behaviour Api.EntityMovement

  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Storylines.ScreenGrouping.{Flow, FlowScreen}
  alias Ecto.{Adapters, Multi}

  @doc """
  Returns the list of all flows for the passed storyline_id

  ## Examples

      iex> list_flows(storyline_id)
      [%Flow{}, ...]

  """
  def list_flows(storyline_id) do
    Flow.list_query(storyline_id) |> Repo.all()
  end

  @doc """
  Creates a default flow for the passed storyline_id

  ## Examples

      iex> create_default_flow(storyline_id_without_a_default_flow)
      {:ok, %Flow{}}

      iex> create_default_flow(storyline_id_with_a_default_flow)
      {:error, %Ecto.Changeset{}}

  """
  def create_default_flow(storyline_id) do
    %Flow{storyline_id: storyline_id}
    |> Flow.create_default_flow_changeset()
    |> Repo.insert()
  end

  @doc """
  Creates a "regular" flow (meaning, not a default flow) for the passed storyline_id

  ## Examples

      iex> create_flow(storyline_id, valid_attrs)
      {:ok, %Flow{}}

      iex> create_flow(storyline_id, invalid_attrs, actor)
      {:error, %Ecto.Changeset{}}

  """

  def create_flow(storyline_id, attrs) do
    max_position = get_flow_max_position(storyline_id)
    attrs = attrs |> Map.put(:position, max_position + 1)

    %Flow{storyline_id: storyline_id}
    |> Flow.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a flow's name

  ## Examples

      iex> rename_flow(flow_id, valid_name, actor)
      {:ok, %Flow{}}

      iex> rename_flow(flow_id, valid_name, bad_actor)
      {:error, :unauthorized}

      iex> rename_flow(flow_id, nil, actor)
      {:error, %Ecto.Changeset{}}

  """
  def rename_flow(flow_id, name, actor) do
    flow = get_flow!(flow_id)
    flow = Repo.preload(flow, storyline: [])

    with :ok <- Api.Authorizer.authorize(flow.storyline, actor, :presenter) do
      flow
      |> Flow.rename_changeset(%{name: name})
      |> Repo.update()
    end
  end

  @doc """
  Adds a screen to a flow in a specific position or :last_position

  ## Examples

      iex> add_screen_to_flow(flow_id, screen_id, position)
      {:ok, %FlowScreen{}}

      iex> add_screen_to_flow(flow_id, screen_id, :last_position)
      {:ok, %FlowScreen{}}

      iex> add_screen_to_flow(flow_id, screen_id, taken_position)
      {:error, %Ecto.Changeset{}}

  """
  def add_screen_to_flow(flow_id, screen_id, :last_position) do
    position = get_flow_screen_max_position(flow_id) + 1

    add_screen_to_flow(flow_id, screen_id, position)
  end

  def add_screen_to_flow(flow_id, screen_id, position) do
    %FlowScreen{flow_id: flow_id, screen_id: screen_id}
    |> FlowScreen.create_changeset(%{position: position})
    |> Repo.insert()
  end

  @doc """
  Adds a screen to the default flow of a storyline in a specific position or :last_position

  ## Examples

      iex> add_screen_to_default_flow(storyline_id, screen_id, position)
      {:ok, %FlowScreen{}}

      iex> add_screen_to_default_flow(storyline_id, screen_id, :last_position)
      {:ok, %FlowScreen{}}

      iex> add_screen_to_default_flow(storyline_id, screen_id, taken_position)
      {:error, %Ecto.Changeset{}}

  """
  def add_screen_to_default_flow(storyline_id, screen_id, :last_position) do
    flow = get_default_flow(storyline_id)
    position = get_flow_screen_max_position(flow.id) + 1

    add_screen_to_default_flow(storyline_id, screen_id, position)
  end

  def add_screen_to_default_flow(storyline_id, screen_id, position) do
    flow = get_default_flow(storyline_id)

    add_screen_to_flow(flow.id, screen_id, position)
  end

  @doc """
  Deletes a flow and moves all of its screens to the default flow of the storyline.
  Will throw an error if you pass the default flow of a storyline.

  ## Examples

      iex> delete_flow(flow_id, actor)
      {:ok, %Flow{}}

      iex> delete_flow(flow_id, bad_actor)
      {:error, :unauthorized}

  """
  def delete_flow(flow_id, actor) do
    flow = get_flow_with_flow_screens!(flow_id)
    flow = flow |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(flow.storyline, actor, :presenter) do
      default_flow = get_default_flow(flow.storyline_id)
      default_flow_screen_max_position = get_flow_screen_max_position(default_flow.id)

      flow_screens_changesets =
        flow.flow_screens
        |> Enum.with_index(1)
        |> Enum.map(fn {flow_screen, index} ->
          %FlowScreen{
            flow_id: default_flow.id,
            screen_id: flow_screen.screen_id
          }
          |> FlowScreen.create_changeset(%{position: default_flow_screen_max_position + index})
        end)

      multi =
        Multi.new()
        |> Multi.run(:delete_flow, fn _repo, _ ->
          flow |> Flow.delete_changeset() |> Repo.delete()
        end)

      multi =
        Multi.run(multi, :compact_flows, fn _repo, _ ->
          compact_flows(flow.storyline_id)
        end)

      flow_screens_changesets
      |> Enum.reduce(multi, fn changeset, multi_acc ->
        Multi.insert(multi_acc, Integer.to_string(changeset.changes.position), changeset)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{delete_flow: deleted_flow}} -> {:ok, deleted_flow}
        {:error, :delete_flow, error, _} -> {:error, error}
      end
    end
  end

  defp compact_flows(storyline_id) do
    flows = list_flows(storyline_id)
    Api.EntityMovement.compact_entities(__MODULE__, flows, Flow)
  end

  @doc """
  Gets the default flow of a storyline_id

  ## Examples

      iex> get_default_flow(storyline_id)
      %FlowScreen{}

      iex> get_default_flow(incorrect_storyline_id)
      nil

  """
  def get_default_flow(storyline_id) do
    storyline_id
    |> Flow.default_flow_query()
    |> Repo.one()
  end

  @doc """
  Changes Flow position and reposition sibling flows accordingly

  ## Examples

      iex> reposition_flow(flow_id, new_position, actor)
      {:ok, multi_map}

      iex> reposition_flow(flow_id, new_position_that_equals_to_current_position, actor)
      {:ok, %{"flow" => %Flow{}}

      iex> reposition_flow(flow_id, new_position, actor)
      {:error, _}

  """
  def reposition_flow(flow_id, new_position, actor) do
    flow = get_flow!(flow_id) |> Repo.preload(storyline: [flows: []])

    with :ok <- Api.Authorizer.authorize(flow.storyline, actor, :presenter) do
      Api.EntityMovement.reposition_entity(__MODULE__, flow, new_position)
    end
  end

  @doc """
  Repositions all the flows screens in order. Useful when a screen is deleted from a flow.

  ## Examples

      iex> compact_flow(flow_id)
      {:ok, multi_map}

      iex> compact_flow(flow_id)
      {:error, error}

  """
  def compact_flow(flow_id) do
    flow = get_flow_with_flow_screens!(flow_id)

    Api.EntityMovement.compact_entities(__MODULE__, flow.flow_screens, FlowScreen)
  end

  @doc """
  Moves a list of screens to a particular position

  We cannot use Api.EntityMovement because that is an abstraction that solely handles single item
  movements. We need to do a more naive approach, because:

    - Screens can belong to multiple flows
    - Screens are not sequential

  Basically this means that any assumptions we are making to efficiently reposition screens is not
  valid anymore.

  When we update the position in all the flow_screens, only if the resources is really changed,
  the changeset will actually run a query on the database. Ecto handles this for us!
  """
  def move_screens(_, _, position, _actor) when position < -1 do
    {:error, :invalid_position}
  end

  def move_screens(screen_ids, target_flow_id, position, actor) do
    flow = Flow |> Repo.get!(target_flow_id) |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(flow.storyline, actor, :presenter) do
      screens =
        FlowScreen
        |> where([s], s.screen_id in ^screen_ids)
        |> Repo.all()
        |> Enum.map(&{&1.screen_id, &1})
        |> Enum.into(%{})

      screens_ordered =
        screen_ids
        |> Enum.map(&Map.get(screens, &1))
        |> Enum.filter(& &1)

      original_flow_screens =
        FlowScreen
        |> where(flow_id: ^target_flow_id)
        |> order_by(:position)
        |> Repo.all()

      flow_screen_ids = screens_ordered |> Enum.map(& &1.id)

      ordered_screens_in_flow =
        if position > 0 do
          {first_screens, last_screens} =
            original_flow_screens
            |> Enum.reject(&(&1.id in flow_screen_ids))
            |> Enum.split(position - 1)

          Enum.concat([first_screens, screens_ordered, last_screens])
        else
          Enum.concat(
            original_flow_screens |> Enum.reject(&(&1.id in flow_screen_ids)),
            screens_ordered
          )
        end

      multi =
        Multi.new()
        |> Multi.run(:deferred, fn _repo, _ ->
          Adapters.SQL.query!(Repo, FlowScreen.defer_position_unique_constraint_query())
          {:ok, nil}
        end)

      changesets =
        ordered_screens_in_flow
        |> Enum.with_index(1)
        |> Enum.map(fn {screen, position} ->
          FlowScreen.reposition_changeset(screen, %{position: position, flow_id: target_flow_id})
        end)
        # we don't want to return unchanged entries
        |> Enum.reject(&(&1.changes == %{}))

      multi =
        changesets
        |> Enum.reduce(multi, fn screen_changeset, multi ->
          Multi.update(multi, {:screen, screen_changeset.data.id}, screen_changeset)
        end)

      # compact all affected flows
      flows =
        screens_ordered
        |> Enum.map(& &1.flow_id)
        |> Enum.uniq()
        |> Enum.reject(&(&1 == target_flow_id))

      multi =
        Enum.reduce(flows, multi, fn flow_id, multi ->
          Multi.run(multi, "compact_flow_#{flow_id}", fn _repo, _ ->
            compact_flow(flow_id)
          end)
        end)

      case Repo.transaction(multi) do
        {:ok, results} ->
          {:ok,
           changesets
           |> Enum.map(&results[{:screen, &1.data.id}])
           |> Api.Repo.preload(:screen)}

        {:error, _, _, _} ->
          {:error, "repositioning failed"}
      end
    end
  end

  @doc """
  Moves the screen to the new position in the past target_flow_id
  Support movement inside the same flow and movement to a new flow

  The new_position argument accepts a positive value and also it accepts
  -1 for the case the user wants to move the screen to the last_position dynamically
  without knowing in advance what is the index of the last position

  ## Examples

      iex> move_screen(screen_id, target_flow_id_that_equals_to_original_flow_id, new_position)
      {:ok, multi_map}

      iex> move_screen(screen_id, target_flow_id_that_equals_to_original_flow_id, new_position_that_equals_to_current_position)
      {:ok, %{"screen" => %Screen{}}

      iex> move_screen(screen_id, target_flow_id_that_equals_to_original_flow_id, new_position)
      {:error, _}

      iex> move_screen(screen_id, target_flow_id_different_than_original_flow_id, new_position)
      {:ok, multi_map}

      iex> move_screen(screen_id, target_flow_id_different_than_original_flow_id, new_position_that_equals_to_current_position)
      {:ok, multi_map}

      iex> move_screen(screen_id, target_flow_id_different_than_original_flow_id, :last)
      {:ok, multi_map}

      iex> move_screen(screen_id, target_flow_id_different_than_original_flow_id, new_position)
      {:error, _}

  """
  def move_screen(screen_id, target_flow_id, new_position) do
    flow_screen = FlowScreen |> Repo.get_by!(screen_id: screen_id) |> Repo.preload(:flow)

    origin_flow = flow_screen.flow

    new_position =
      if new_position == :last do
        pos = get_flow_screen_max_position(target_flow_id)

        if origin_flow.id == target_flow_id do
          pos
        else
          pos + 1
        end
      else
        new_position
      end

    if origin_flow.id == target_flow_id do
      Api.EntityMovement.reposition_entity(__MODULE__, flow_screen, new_position)
    else
      move_screen_to_flow(
        screen_id,
        origin_flow.id,
        target_flow_id,
        flow_screen.position,
        new_position
      )
    end
  end

  defp move_screen_to_flow(
         screen_id,
         origin_flow_id,
         target_flow_id,
         current_position,
         new_position
       ) do
    origin_flow = get_flow_with_flow_screens!(origin_flow_id)
    target_flow = get_flow_with_flow_screens!(target_flow_id)

    flow_screen =
      origin_flow.flow_screens
      |> Enum.find(fn flow_screen -> flow_screen.screen_id == screen_id end)

    # First, Defer constraints
    multi =
      Multi.new()
      |> Multi.run("deferred", fn _repo, _ ->
        Adapters.SQL.query!(Repo, FlowScreen.defer_position_unique_constraint_query())
        {:ok, nil}
      end)

    # Second, remove screen from original flow
    multi =
      multi
      |> Multi.delete("remove_screen_from_origin_flow", flow_screen)

    # Third, reposition screens in original flow
    origin_flow_screens_changesets =
      origin_flow.flow_screens
      |> Enum.filter(fn flow_screen -> flow_screen.position > current_position end)
      |> Enum.map(fn flow_screen ->
        FlowScreen.reposition_changeset(flow_screen, %{position: flow_screen.position - 1})
      end)

    multi =
      origin_flow_screens_changesets
      |> Enum.reduce(multi, fn changeset, multi_acc ->
        key = "origin_flow#{Integer.to_string(changeset.changes.position)}"
        Multi.update(multi_acc, key, changeset)
      end)

    # Forth, reposition relevant screens in destination flow
    target_flow_screens_changesets =
      target_flow.flow_screens
      |> Enum.filter(fn flow_screen -> flow_screen.position >= new_position end)
      |> Enum.map(fn flow_screen ->
        FlowScreen.reposition_changeset(flow_screen, %{position: flow_screen.position + 1})
      end)

    multi =
      target_flow_screens_changesets
      |> Enum.reduce(multi, fn changeset, multi_acc ->
        key = "target_flow#{Integer.to_string(changeset.changes.position)}"
        Multi.update(multi_acc, key, changeset)
      end)

    # Fifth, add screen to destination flow
    multi
    |> Multi.run("add_screen_to_target_flow", fn _repo, _changes_so_far ->
      add_screen_to_flow(target_flow_id, screen_id, new_position)
    end)
    |> Repo.transaction()
  end

  @impl Api.EntityMovement
  def position_field_for_entity(%FlowScreen{}), do: :position

  @impl Api.EntityMovement
  def position_field_for_entity(%Flow{}), do: :position

  @impl Api.EntityMovement
  def position_field_for_entity_type(Flow), do: :position

  @impl Api.EntityMovement
  def position_field_for_entity_type(FlowScreen), do: :position

  @impl Api.EntityMovement
  def get_entities_to_reposition(%Flow{} = flow), do: list_flows(flow.storyline_id)

  @impl Api.EntityMovement
  def get_entities_to_reposition(%FlowScreen{} = flow_screen),
    do: get_flow_with_flow_screens!(flow_screen.flow_id).flow_screens

  @impl Api.EntityMovement
  def reposition_changeset_func_for_entity(%Flow{}),
    do: reposition_changeset_func_for_entity_type(Flow)

  @impl Api.EntityMovement
  def reposition_changeset_func_for_entity(%FlowScreen{}),
    do: reposition_changeset_func_for_entity_type(FlowScreen)

  @impl Api.EntityMovement
  def reposition_changeset_func_for_entity_type(Flow), do: &Flow.reposition_changeset/2

  @impl Api.EntityMovement
  def reposition_changeset_func_for_entity_type(FlowScreen),
    do: &FlowScreen.reposition_changeset/2

  defp get_flow!(id), do: Repo.get!(Flow, id)

  defp get_flow_with_flow_screens!(id) do
    get_flow!(id) |> Repo.preload(flow_screens: FlowScreen.order_by_position_query())
  end

  defp get_flow_max_position(storyline_id),
    do: storyline_id |> Flow.list_query() |> Repo.aggregate(:max, :position)

  def get_flow_screen_max_position(flow_id) do
    FlowScreen.max_position_query(flow_id) |> Repo.one() || 0
  end
end
