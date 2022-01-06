defmodule Api.Storylines.Copying do
  @moduledoc """
  Helps copying entities within a storyline, these copy are usually shallow and only handles
  Storylines entities, e.g if  you copy a screen, it'll not copy the Edits.
  Please read each method documentation
  """
  alias Api.Repo
  alias Api.Storylines
  alias Api.Storylines.Demos.Demo
  alias Api.Storylines.SmartObjects
  alias Api.Storylines.{Editing, Screen, ScreenGrouping, Storyline}
  alias Api.Storylines.Editing.Edit
  alias Api.Storylines.Editing.Edit.Link
  alias Api.Storylines.Editing.Edit.Link.ScreenDestination
  alias Api.Storylines.ScreenGrouping.{Flow, FlowScreen}
  alias Ecto.Multi

  def copy_flows(origin_storyline_id, target) do
    flows = Api.Storylines.list_flows(origin_storyline_id)

    flows
    |> Enum.reduce(Multi.new(), fn flow, multi ->
      multi |> Multi.append(flow |> copy_flow_multi(target))
    end)
    # Since we copied screens that might include links:
    # We remap both edits and smart object instances edits links to the copied screens
    |> Multi.merge(&remap_edits(&1))
    |> Multi.merge(&remap_instances(&1))
    |> Repo.transaction()
    |> case do
      {:error, _, :unauthorized, _} ->
        {:error, :unauthorized}

      {:ok, result} ->
        {:ok, result}
    end
  end

  defp remap_instances(changes) do
    changes
    |> Enum.filter(&match?({{:copied_screen, _id}, _}, &1))
    |> Enum.reduce(Multi.new(), fn {{:copied_screen, _from_id}, %{to_screen: copied_screen}},
                                   multi ->
      multi
      |> Ecto.Multi.update({:update_instances_screen, copied_screen.id}, fn _ ->
        instances =
          remap_instances_screen(
            changes,
            copied_screen.smart_object_instances,
            copied_screen.id
          )
          |> SmartObjects.Instance.to_attributes()

        Screen.update_changeset(copied_screen, %{
          smart_object_instances: instances
        })
      end)
    end)
  end

  defp remap_instances_screen(changes, origin_instances, to_screen_id) do
    origin_instances
    |> Enum.map(fn instance ->
      %{edits: origin_instance_edits} = SmartObjects.convert_edits(instance, :edits)

      %{edits_overrides: origin_instance_edits_overrides} =
        SmartObjects.convert_edits(instance, :edits_overrides)

      new_instance_edits =
        origin_instance_edits
        |> Enum.map(fn edit -> %Edit{edit | screen_id: to_screen_id} end)
        |> Enum.map(fn edit -> find_and_remap_edit_screen(edit, changes) end)

      new_instance_edits_overrides =
        origin_instance_edits_overrides
        |> Enum.map(fn edit_override -> %Edit{edit_override | screen_id: to_screen_id} end)
        |> Enum.map(fn edit_override -> find_and_remap_edit_screen(edit_override, changes) end)

      %SmartObjects.Instance{
        instance
        | screen_id: to_screen_id,
          edits: new_instance_edits,
          edits_overrides: new_instance_edits_overrides
      }
    end)
  end

  defp remap_instances_screen(copied_instances, to_screen_id) do
    copied_instances
    |> Enum.map(fn instance ->
      %{edits: origin_instance_edits} = SmartObjects.convert_edits(instance, :edits)

      %{edits_overrides: origin_instance_edits_overrides} =
        SmartObjects.convert_edits(instance, :edits_overrides)

      remapped_instance_edits =
        origin_instance_edits
        |> Enum.map(fn edit -> %Edit{edit | screen_id: to_screen_id} |> Edit.to_map() end)

      remapped_instance_edits_overrides =
        origin_instance_edits_overrides
        |> Enum.map(fn edit_override ->
          %Edit{edit_override | screen_id: to_screen_id} |> Edit.to_map()
        end)

      %SmartObjects.Instance{
        instance
        | screen_id: to_screen_id,
          edits: remapped_instance_edits,
          edits_overrides: remapped_instance_edits_overrides
      }
    end)
  end

  @doc """
  Finds edit related copied screen id in multi and updates edits destination accordingly

  ## Examples

      iex> find_and_remap_edit_screen(edit, copied_flows)
      %Edit{}

  """
  def find_and_remap_edit_screen(edit, copied_flows) do
    case Editing.Edit.link_to_screen?(edit) do
      true ->
        copied_screen_id = find_new_target_screen_id(copied_flows, edit)
        update_link_edit_destination(copied_screen_id, edit)

      false ->
        Edit.to_map(edit)
    end
  end

  defp remap_edits(changes) do
    changes
    |> Enum.filter(&match?({{:copied_screen, _id}, _}, &1))
    |> Enum.flat_map(fn {{:copied_screen, _id}, %{to_screen: %{id: to_screen_id} = _to_screen}} ->
      Editing.list_edits(to_screen_id)
    end)
    # Get all edits of the copied screen
    |> Enum.filter(&Editing.Edit.link_to_screen?(&1))
    |> Enum.reduce(Multi.new(), fn edit, multi ->
      copied_screen_id = find_new_target_screen_id(changes, edit)
      # Our data model might include issues, such as a copied link from an even older storyline
      if copied_screen_id == nil do
        multi
      else
        multi
        |> Multi.run({:update_edit, edit.id}, fn _, _ ->
          edit = update_link_edit_destination(copied_screen_id, edit)
          Editing.update_edits(copied_screen_id, [edit])
        end)
      end
    end)
  end

  def update_link_edit_destination(target_screen_id, edit) do
    edit_fields = Editing.Edit.__schema__(:fields)

    destination =
      Editing.Edit.props(edit)
      |> Link.destination()

    edit =
      put_in(
        edit,
        [Access.key!(:link_edit_props)],
        %{
          destination: %{
            kind: "screen",
            id: target_screen_id,
            delay_ms: destination.delay_ms
          }
        }
      )

    edit
    |> Map.from_struct()
    |> Map.take(edit_fields)
  end

  def find_new_target_screen_id(changes, edit) do
    # NOTE(ben) Get the current target of the linkEdit
    origin_screen_id =
      Editing.Edit.props(edit)
      |> Link.destination()
      |> ScreenDestination.id()

    # NOTE(ben) Get the id of the copied screen
    res =
      changes
      |> Enum.filter(fn change ->
        case change do
          {{:copied_screen, ^origin_screen_id}, _} -> true
          _ -> false
        end
      end)

    case res do
      [] -> nil
      [{{:copied_screen, _}, %{to_screen: copied_screen}}] -> copied_screen.id
    end
  end

  defp copy_flow_multi(%Flow{} = origin_flow, target) do
    origin_flow =
      origin_flow |> Repo.preload(screens: Screen.all_query(), storyline: [:start_screen])

    start_screen = origin_flow.storyline.start_screen
    origin_screens = origin_flow.screens
    copied_flow_key = {:copied_flow, origin_flow.id}

    multi =
      Multi.new()
      # First we copy the flow, preseving it's is_default state
      |> Multi.run(copied_flow_key, fn _repo, _changes_so_far ->
        Storylines.copy_flow(target, origin_flow)
      end)

    # Next, for each screen, we copy it

    origin_screens
    |> Enum.reduce(multi, fn screen, multi ->
      screen = screen |> Repo.preload([:flow_screen])

      screen_key = {:copied_screen, screen.id}

      multi
      # First we copy the screen
      |> Multi.run(screen_key, fn _repo, changes_so_far ->
        copied_flow = changes_so_far |> Map.get(copied_flow_key)

        # once we remove storyline_id from screens table we won't need this condition (issue #1708)
        # credo:disable-for-lines:5 Credo.Check.Refactor.Nesting
        result =
          case target do
            %Storyline{} ->
              copy_screen(screen, copied_flow, %{storyline_id: target.id})

            %Demo{} ->
              copy_screen(screen, copied_flow, %{storyline_id: nil})
          end

        with {:ok, copied_screen} <- result do
          {:ok, %{from_screen_id: screen.id, to_screen: copied_screen}}
        end
      end)
      # If that screen was the start_screen, we set it as such on the target_storyline
      |> Multi.run({:start_screen, screen.id}, fn _repo, changes_so_far ->
        if screen.id == start_screen.id do
          copied_screen = changes_so_far |> Map.get(screen_key)
          Storylines.update_start_screen(target, copied_screen.to_screen.id)
        else
          {:ok, nil}
        end
      end)
    end)
  end

  @doc """
  Copies a screen, including edits, in the same storyline.
  When copying to a different flow, the screen is automatically put to the end of the flow.
  You can supply different attribute(such as name/storyline_id} in attrs

  ## Examples

        iex> copy_screen(%Screen{}, %Flow{}, %{name: "new name"})
        {:ok, %Screen{name: "new name"}}


        iex> copy_screen(%Screen{}, %Flow{}, %{invalid: "option"} )
        {:error, %Changeset}
  """
  def copy_screen(%Screen{} = screen, %Flow{} = flow, attrs) do
    attrs =
      %{
        name: screen.name,
        storyline_id: screen.storyline_id
      }
      |> Map.merge(attrs)

    screen = Repo.preload(screen, :flow_screen)
    current_screen_attrs = screen |> Map.from_struct()
    attrs = current_screen_attrs |> Map.merge(attrs)

    Multi.new()
    |> Multi.insert(:copy_screen, fn %{} ->
      attrs = Map.update(attrs, :original_dimensions, %{}, &to_map/1)
      attrs = Map.update(attrs, :available_dimensions, [], &to_map/1)

      attrs =
        Map.update(attrs, :smart_object_instances, [], &SmartObjects.Instance.to_attributes/1)

      %Screen{storyline_id: attrs.storyline_id}
      |> Screen.copy_changeset(attrs)
    end)
    |> Multi.run(:smart_object_instances_screen, fn _repo, %{copy_screen: copied_screen} ->
      screen_instances =
        copied_screen.smart_object_instances
        |> remap_instances_screen(copied_screen.id)
        |> SmartObjects.Instance.to_attributes()

      screen =
        Screen.update_changeset(
          copied_screen,
          %{smart_object_instances: screen_instances}
        )
        |> Repo.update!()

      {:ok, screen.smart_object_instances}
    end)
    # Next we create new FlowScreen and connect it to the flow and screen we just copied
    |> Multi.insert({:flow_screen, screen.id}, fn changes_so_far ->
      copied_screen = changes_so_far |> Map.get(:copy_screen)
      copied_flow = flow |> Repo.preload(:flow_screens)

      target_position =
        if flow.id == screen.flow_screen.flow_id do
          ScreenGrouping.get_flow_screen_max_position(flow.id) + 1
        else
          screen.flow_screen.position
        end

      %FlowScreen{flow_id: copied_flow.id, screen_id: copied_screen.id}
      |> FlowScreen.create_changeset(%{position: target_position})
    end)
    |> Multi.run(:copied_edits, fn _repo, %{copy_screen: screen_copy} ->
      Editing.copy_edits(screen.id, screen_copy.id)
    end)
    |> Multi.run(:reposition_screen, fn _, %{copy_screen: screen_copy} ->
      if flow.id == screen.flow_screen.flow_id do
        ScreenGrouping.move_screen(
          screen_copy.id,
          flow.id,
          screen.flow_screen.position + 1
        )
      else
        {:ok, screen_copy}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:error, _, :unauthorized, _} -> {:error, :unauthorized}
      {:ok, %{copy_screen: screen}} -> {:ok, Api.Repo.reload(screen)}
    end
  end

  def copy_screens(screen_ids, attr) do
    screens = Screen.all_query(screen_ids) |> Api.Repo.all() |> Api.Repo.preload(:flow)

    screens
    |> Enum.reduce(Multi.new(), fn screen, multi ->
      attr =
        case Map.pop(attr, :prepend_name) do
          {prepend_name, attr} when is_binary(prepend_name) ->
            Map.put(attr, :name, prepend_name <> screen.name)

          {_, attr} ->
            attr
        end

      Multi.run(multi, screen.id, fn _, _ ->
        copy_screen(screen, screen.flow, attr)
      end)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, result_map} ->
        {:ok, screen_ids |> Enum.map(&Map.get(result_map, &1)) |> Enum.filter(& &1)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp to_map(val) do
    val |> Jason.encode!() |> Jason.decode!()
  end
end
