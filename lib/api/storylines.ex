defmodule Api.Storylines do
  @moduledoc """
  The Storylines context.
  """

  import Ecto.Query, warn: false

  alias Api.Repo

  alias Api.Storylines.{
    Collaborator,
    Copying,
    Editing,
    Screen,
    ScreenGrouping,
    Storyline
  }

  alias Api.Storylines.Demos
  alias Api.Storylines.Demos.Demo
  alias Api.Storylines.ScreenGrouping.Flow
  alias Api.Storylines.ScreenGrouping.FlowScreen
  alias Ecto.Multi

  defdelegate create_default_flow(storyline_id), to: ScreenGrouping
  defdelegate delete_flow(flow_id, actor), to: ScreenGrouping
  defdelegate get_default_flow(storyline_id), to: ScreenGrouping
  defdelegate list_flows(storyline_id), to: ScreenGrouping
  defdelegate rename_flow(flow_id, name, actor), to: ScreenGrouping
  defdelegate reposition_flow(flow_id, position, actor), to: ScreenGrouping
  defdelegate move_screens(screen_ids, target_flow_id, position, actor), to: ScreenGrouping
  defdelegate copy_flows(origin_storyline_id, target_storyline), to: Copying

  @doc """
  Returns the list of all storylines, including private & public

  ## Examples

      iex> list_all_storylines(member_id, company_id)
      [%Storyline{}, ...]

  """
  def list_all_storylines(member_id, company_id) do
    Storyline.all_storylines_query(member_id, company_id) |> Repo.all()
  end

  @doc """
  Returns the list of only private storyliens.

  ## Examples

    iex> list_private_storylines(owner_id, company_id)
    [%Storyline{}, ...]

  """
  def list_private_storylines(owner_id, company_id) do
    Repo.all(Storyline.private_storylines_query(owner_id, company_id))
  end

  @doc """
  Returns the list of only public storyliens.

  ## Examples

    iex> list_public_storylines(company_id)
    [%Storyline{}, ...]

  """
  def list_public_storylines(company_id) do
    Repo.all(Storyline.public_storylines_query(company_id))
  end

  @doc """
  Gets a single storyline.

  Raises `Ecto.NoResultsError` if the Storyline does not exist.

  ## Examples

      iex> get_storyline!(123)
      %Storyline{}

      iex> get_storyline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_storyline!(id), do: Repo.get!(Storyline, id)

  @doc """
  Gets a single storyline as a result tuple, with authorization

  ## Examples

      iex> fetch(123, actor)
      %Storyline{}

      iex> fetch(123, bad_actor)
      {:error, :unauthorized}

      iex> fetch(456, actor)
      {:error, :not_found}

  """
  def fetch(id, actor) do
    with {:ok, storyline} <- Repo.fetch(Storyline, id),
         :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
      {:ok, storyline}
    end
  end

  @doc """
  Gets a single storyline as a result tuple

  ## Examples

      iex> fetch(123)
      {:ok, %Storyline{}}

      iex> fetch(456)
      {:error, :not_found}
  """
  def fetch(id), do: Repo.fetch(Storyline, id)

  @doc """
  Creates a private storyline without applying Patches

  ## Examples

      iex> create_private_storyline(%{field: value}, actor)
      {:ok, %Storyline{}}

      iex> create_private_storyline(%{field: bad_value}, actor)
      {:error, %Ecto.Changeset{}}

      iex> create_private_storyline(%{field: value}, bad_actor)
      {:error, :unauthorized}

  """
  def create_private_storyline(attrs, actor) do
    name = attrs |> Map.get(:name, generate_name(actor.id, actor.company_id))
    attrs = attrs |> Map.merge(%{is_public: false, name: name})

    changeset =
      %Storyline{owner_id: actor.id}
      |> Storyline.create_changeset(attrs)

    storyline = Ecto.Changeset.apply_changes(changeset)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :creator) do
      Multi.new()
      |> Multi.run(:storyline, fn _, _ ->
        Repo.insert(changeset)
      end)
      |> Multi.run(:create_default_flow, fn _, %{storyline: storyline} ->
        create_default_flow(storyline.id)
      end)
      |> Multi.run(:create_storyline_settings, fn _, %{storyline: storyline} ->
        Api.Settings.create_storyline_settings(storyline.id)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{storyline: storyline}} ->
          {:ok, storyline}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  defp generate_name(member_id, company_id) do
    name_template = "New Storyline"
    captured_index_key = "index"
    name_template_regex = ~r/^#{name_template}$/i
    name_regex = ~r/^#{name_template} (?<#{captured_index_key}>[[:digit:]]+)$/i

    storylines = list_all_storylines(member_id, company_id)

    max_current_index =
      storylines
      |> Enum.map(fn storyline -> storyline.name end)
      |> Enum.filter(fn name ->
        String.match?(name, name_regex) || String.match?(name, name_template_regex)
      end)
      |> Enum.map(fn name -> Regex.named_captures(name_regex, name) end)
      |> Enum.map(fn captured -> captured[captured_index_key] || "1" end)
      |> Enum.map(&Integer.parse/1)
      |> Enum.map(fn {result, _} -> result end)
      |> Enum.max(fn -> 0 end)

    name_suffix =
      cond do
        max_current_index > 0 ->
          " #{max_current_index + 1}"

        max_current_index ->
          ""
      end

    "#{name_template}#{name_suffix}"
  end

  @doc """
  Creates a public storyline without applying Patches

  ## Examples

      iex> create_public_storyline(%{field: value}, actor)
      {:ok, %Storyline{}}

      iex> create_public_storyline(%{field: bad_value}, actor)
      {:error, %Ecto.Changeset{}}

  """
  def create_public_storyline(attrs, actor) do
    attrs = attrs |> Map.merge(%{is_public: true})

    changeset =
      %Storyline{owner_id: actor.id}
      |> Storyline.create_changeset(attrs)

    with :ok <- Api.Authorizer.authorize(Ecto.Changeset.apply_changes(changeset), actor, :creator) do
      Multi.new()
      |> Multi.run(:storyline, fn _repo, _ ->
        changeset |> Repo.insert()
      end)
      |> Multi.run(:create_default_flow, fn _repo,
                                            %{
                                              storyline: storyline
                                            } ->
        create_default_flow(storyline.id)
      end)
      |> Multi.run(:create_storyline_settings, fn _repo,
                                                  %{
                                                    storyline: storyline
                                                  } ->
        Api.Settings.create_storyline_settings(storyline.id)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{storyline: storyline}} ->
          {:ok, storyline}

        {:error, _step_name, error, _} ->
          {:error, error}
      end
    end
  end

  @doc """
  Deletes a storyline.

  ## Examples

      iex> delete_storyline(storyline)
      {:ok, %Storyline{}}

      iex> delete_storyline(storyline)
      {:error, %Ecto.Changeset{}}

  """
  def delete_storyline(%Storyline{} = storyline) do
    Repo.delete(storyline)
  end

  @doc """
  Updates a storyline

  ## Examples

        iex> update_storyline(storyline, valid_attr, actor)
        {:ok, %Storyline{}}

        iex> update_storyline(storyline, invalid_attrs, actor)
        {:error, %Ecto.Changeset{}}

        iex> update_storyline(storyline, invalid_attrs, wrong_actor)
        {:error, :unauthorized}
  """
  def update_storyline(%Storyline{} = storyline, attrs, actor) do
    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      storyline
      |> Storyline.update_changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Returns the list of screens.

  ## Examples

      iex> list_screens(storyline)
      [%Screen{}, ...]

  """
  def list_screens(%Storyline{} = storyline) do
    storyline = storyline |> Repo.preload(screens: Screen.all_query())
    storyline.screens
  end

  @doc """
  Gets a single screen.

  Raises `Ecto.NoResultsError` if the Screen does not exist.

  ## Examples

      iex> get_screen!(123)
      %Screen{}

      iex> get_screen!(456)
      ** (Ecto.NoResultsError)

  """
  def get_screen!(id), do: Repo.get!(Screen, id)

  @doc """
  Gets a single screen.

  ## Examples

      iex> fetch_screen(123, actor)
      %Screen{}

      iex> fetch_screen(123, bad_actor)
      {:error, :unauthorized}

      iex> fetch_screen(456, actor)
      {:error, :not_found}

  """
  def fetch_screen(id, actor) do
    with {:ok, screen} <- Repo.fetch(Screen, id),
         screen <- screen |> Repo.preload(storyline: []),
         :ok <- Api.Authorizer.authorize(screen.storyline, actor, :viewer) do
      {:ok, screen}
    end
  end

  @doc """
  Adds a screen to a flow.
  By default we add to the last position, e.g at the end.
  But you could pass an index as the last argument to set specific position

  ## Examples

      iex> add_screen_to_flow(storyline, flow, %{field: value})
      {:ok, %Screen{}}

      iex> add_screen_to_flow(storyline, flow, %{field: bad_value})
      {:error, failed_operation, failed_value, changes_so_far}

  """
  def add_screen_to_flow(
        %Storyline{} = storyline,
        %Flow{} = flow,
        attrs \\ %{}
      ) do
    result =
      create_screen_multi(storyline, attrs)
      |> Multi.run(:flow_screen, fn _repo, %{screen: screen} ->
        ScreenGrouping.add_screen_to_flow(flow.id, screen.id, :last_position)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{screen: screen}} ->
        {:ok, screen}

      {:error, _failed_operation, _failed_value, _changes_so_far} = err ->
        err
    end
  end

  @doc """
  Adds a screen to the default flow in the storyline.
  By default we add to the last position, e.g at the end.
  But you could pass an index as the last argument to set specific position

  ## Examples

      iex> add_screen_to_default_flow(storyline, actor)
      {:ok, %Screen{}}

      iex> add_screen_to_default_flow(storyline, actor, %{field: value})
      {:ok, %Screen{}}

      iex> add_screen_to_default_flow(storyline, actor, %{field: value})
      {:ok, %Screen{}}

      iex> add_screen_to_default_flow(storyline, actor, %{field: bad_value})
      {:error, failed_operation, failed_value, changes_so_far}

  """
  def add_screen_to_default_flow(%Storyline{} = storyline, actor, attrs \\ %{}) do
    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      add_screen_to_default_flow_unauthorized(storyline, attrs)
    end
  end

  def add_screen_to_default_flow_unauthorized(%Storyline{} = storyline, attrs \\ %{}) do
    result =
      create_screen_multi(storyline, attrs)
      |> Multi.run(:flow_screen, fn _repo, %{screen: screen} ->
        ScreenGrouping.add_screen_to_default_flow(storyline.id, screen.id, :last_position)
      end)
      |> Multi.update(:update_last_edited, update_last_edited(storyline))
      |> Repo.transaction()

    case result do
      {:ok, %{screen: screen}} ->
        {:ok, screen}

      {:error, _failed_operation, _failed_value, _changes_so_far} = err ->
        err
    end
  end

  defp create_screen_multi(%Storyline{} = storyline, attrs) do
    Multi.new()
    |> Multi.insert(:screen, fn _ ->
      %Screen{storyline_id: storyline.id}
      |> Screen.create_changeset(attrs)
    end)
    |> Multi.update(:storyline, fn %{screen: screen} ->
      storyline = Repo.get!(Storyline, storyline.id)

      if has_start_screen?(storyline) do
        Ecto.Changeset.change(storyline)
      else
        Storyline.update_changeset(storyline, %{start_screen_id: screen.id})
      end
    end)
  end

  @doc """
  Updates a screen.

  ## Examples

      iex> update_screen(screen, %{field: new_value}, actor)
      {:ok, %Screen{}}

      iex> update_screen(screen, %{field: bad_value}, actor)
      {:error, %Ecto.Changeset{}}

      iex> update_screen(screen, %{field: bad_value}, actor)
      {:error, :unauthorized}

  """
  def update_screen(%Screen{} = screen, attrs, actor) do
    screen = Repo.preload(screen, storyline: [])

    with :ok <- Api.Authorizer.authorize(screen.storyline, actor, :presenter) do
      screen
      |> Screen.update_changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Deletes a screen, If you're trying to delete a start screen and there are other screens,
  we set the start screen to be another screen.
  If there are no other screens, we delete the start_screen f_key

  ## Examples

      iex> delete_screen(screen)
      {:ok, %Screen{}}

      iex> delete_screen(screen)
      {:error, %Ecto.Changeset{}}

  """
  def delete_screen(%Screen{} = screen) do
    screen = screen |> Repo.preload([:storyline, :flow])
    storyline = screen.storyline |> Repo.preload([:screens])
    flow = screen.flow

    # If we're trying to delete a start screen but we've more screens
    multi =
      if start_screen?(storyline, screen.id) do
        if storyline.screens |> Enum.count() > 1 do
          new_start_screen = storyline.screens |> Enum.reject(&(&1.id == screen.id)) |> Enum.at(0)

          Multi.new()
          |> Ecto.Multi.update(
            :storyline,
            Storyline.update_changeset(storyline, %{start_screen_id: new_start_screen.id})
          )
          |> Multi.delete(:screen, screen |> Screen.delete_changeset())
        else
          Multi.new()
          |> Multi.update(
            :storyline,
            Storyline.update_changeset(storyline, %{start_screen_id: nil})
          )
          |> Multi.delete(:screen, screen |> Screen.delete_changeset())
        end
      else
        Multi.new()
        |> Multi.delete(:screen, screen |> Screen.delete_changeset())
      end

    multi =
      Multi.run(multi, :links, fn _, _ ->
        Editing.delete_links_to_screen(screen.id)
        {:ok, nil}
      end)

    # Reposition screens in the flow
    multi =
      Multi.run(multi, :compact_flow, fn _repo, _ ->
        ScreenGrouping.compact_flow(flow.id)
      end)

    multi = Multi.update(multi, :update_last_edited, update_last_edited(storyline))

    multi
    |> Repo.transaction()
  end

  @doc """
  Deletes screens from a storyline, If you're trying to delete a start screen and there are other
  screens, we set the start screen to be another screen. If there are no other screens, we delete
  the start_screen f_key

  ## Examples

      iex> delete_screens(storyline, [%Screen{}])
      {:ok, [%Screen{..}]}

      iex> delete_screens(storyline, [%Screen{}])
      {:error, %Ecto.Changeset{}}

  """
  def delete_screens(%Storyline{} = storyline, screens) do
    screens =
      screens |> Enum.filter(&(&1.storyline_id == storyline.id)) |> Repo.preload(:flow_screen)

    screen_ids = Enum.map(screens, & &1.id)

    # If we're trying to delete a start screen but we've more screens
    multi =
      case {contains_start_screen?(storyline, screen_ids),
            Enum.reject(storyline.screens, &(&1.id in screen_ids))} do
        {false, _} ->
          Multi.new()

        {true, [%Screen{} = new_start_screen | _]} ->
          Multi.new()
          |> Ecto.Multi.update(
            :storyline,
            Storyline.update_changeset(storyline, %{start_screen_id: new_start_screen.id})
          )

        {true, _} ->
          Multi.new()
          |> Multi.update(
            :storyline,
            Storyline.update_changeset(storyline, %{start_screen_id: nil})
          )
      end

    # run delete on all screens
    multi = Multi.delete_all(multi, :screens, from(Screen) |> where([s], s.id in ^screen_ids))

    multi =
      Enum.reduce(screen_ids, multi, fn screen_id, multi ->
        Multi.run(multi, "links_#{screen_id}", fn _, _ ->
          Editing.delete_links_to_screen(screen_id)
          {:ok, nil}
        end)
      end)

    # Reposition screens in the flows
    flows =
      screens
      |> Enum.map(& &1.flow_screen.flow_id)
      |> Enum.uniq()

    multi =
      Enum.reduce(flows, multi, fn flow_id, multi ->
        Multi.run(multi, "compact_flow_#{flow_id}", fn _repo, _ ->
          ScreenGrouping.compact_flow(flow_id)
        end)
      end)

    multi = Multi.update(multi, :update_last_edited, update_last_edited(storyline))

    case Repo.transaction(multi) do
      {:ok, _} -> {:ok, screens}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking screen changes.

  ## Examples

      iex> change_screen(screen)
      %Ecto.Changeset{data: %Screen{}}

  """
  def change_screen(%Screen{} = screen, attrs \\ %{}) do
    Screen.update_changeset(screen, attrs)
  end

  @doc """
  Returns the list of collaborators.

  ## Examples

      iex> list_collaborators(storyline)
      [%Collaborator{}, ...]

  """
  def list_collaborators(%Storyline{} = storyline) do
    Collaborator.by_storyline_id_query(storyline.id) |> Repo.all()
  end

  @doc """
  Returns true if a member is a collaborator, false otherwise

  ## Examples

      iex> is_collaborator(storyline, member_id)
      true

  """
  def is_collaborator(%Storyline{} = storyline, member_id) do
    Collaborator.by_storyline_member_query(storyline.id, member_id) |> Repo.one() != nil
  end

  @doc """
  Returns true if a member is the owner of the storyline, false otherwise

  ## Examples

      iex> is_owner(storyline, member_id)
      true

  """
  def is_owner(storyline, member_id) do
    storyline.owner_id == member_id
  end

  @doc """
  Creates a collaborator.

  ## Examples

      iex> create_collaborator(storyline, member.id)
      {:ok, %Collaborator{}}

      iex> create_collaborator(storyline, not_a_member.id)
      {:error, %Ecto.Changeset{}}

  """
  def add_collaborator(%Storyline{owner_id: owner_id} = storyline, member_id, actor) do
    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      if owner_id == member_id do
        changeset =
          %Collaborator{}
          |> Ecto.Changeset.cast(%{}, [])
          |> Ecto.Changeset.add_error(:owner, "Can't add owner as a collaborator")

        {:error, changeset}
      else
        %Collaborator{}
        |> Collaborator.add_changeset(%{storyline_id: storyline.id, member_id: member_id})
        |> Repo.insert()
      end
    end
  end

  @doc """
  Deletes a collaborator.

  ## Examples

      iex> remove_collaborator(storyline, member, actor)
      :ok

  """
  def remove_collaborator(%Storyline{} = storyline, member_id, actor) do
    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      {1, _} =
        Collaborator.by_storyline_member_query(storyline.id, member_id) |> Repo.delete_all()

      :ok
    end
  end

  defp start_screen?(storyline, screen_id) do
    storyline.start_screen_id == screen_id
  end

  defp contains_start_screen?(storyline, screen_ids) do
    storyline.start_screen_id in screen_ids
  end

  defp has_start_screen?(storyline) do
    storyline.start_screen_id != nil
  end

  @doc """
  Copies one storyline/demo flow to another storyline/demo

  ## Examples

      iex> copy_flow(storyline, flow)
      {:ok}

  """
  def copy_flow(%Storyline{id: storyline_id}, %Flow{} = origin_flow) do
    if origin_flow.is_default do
      %ScreenGrouping.Flow{storyline_id: storyline_id}
      |> ScreenGrouping.Flow.create_default_flow_changeset()
      |> Repo.insert()
    else
      %ScreenGrouping.Flow{storyline_id: storyline_id}
      |> ScreenGrouping.Flow.create_changeset(%{
        name: origin_flow.name,
        position: origin_flow.position
      })
      |> Repo.insert()
    end
  end

  def copy_flow(%Demo{id: demo_id}, %Flow{} = origin_flow) do
    demo_version = Demos.get_active_demo_version!(demo_id)

    if origin_flow.is_default do
      %Flow{demo_version_id: demo_version.id}
      |> Flow.create_default_flow_changeset()
      |> Repo.insert()
    else
      %Flow{demo_version_id: demo_version.id}
      |> Flow.create_changeset(%{name: origin_flow.name, position: origin_flow.position})
      |> Repo.insert()
    end
  end

  @doc """
  Updates start screen of demo or storyline

  ## Examples

      iex> update_start_screen(storyline, screen_id)
      {:ok}

  """
  def update_start_screen(%Storyline{} = storyline, screen_id) do
    Storyline.update_changeset(storyline, %{
      start_screen_id: screen_id
    })
    |> Repo.update()
  end

  def update_start_screen(%Demo{} = demo, screen_id) do
    Demos.update_start_screen(demo, %{
      start_screen_id: screen_id
    })
    |> Repo.update()
  end

  @doc """
  Get the screen ids that are unlinked in a storyline, meaning that they are not:
  - A destination of a link edit
  - Guide annotation screen transition

  ## Examples

      iex> unlinked_screen_ids("abc")
      #MapSet<["ghi"]>
  """

  def unlinked_screen_ids(storyline_id) do
    alias Api.Annotations.Annotation
    alias Api.Storylines.Editing.Edit
    alias Api.Storylines.Editing.Edit.Link
    alias Api.Storylines.Editing.Edit.Link.ScreenDestination

    storyline_screen_ids = Screen.storyline_screen_ids(storyline_id) |> Repo.all()

    linked_screens_edit =
      Edit.link_edits_between_screens(storyline_screen_ids)
      |> Repo.all()
      |> Enum.reduce(MapSet.new(), fn
        %Edit{link_edit_props: %Link{destination: %ScreenDestination{id: screen_id}}}, acc ->
          MapSet.put(acc, screen_id)

        _, acc ->
          acc
      end)

    {_, linked_screens_annotations} =
      Annotation.all_annotations_in_screens_query(storyline_screen_ids)
      |> Repo.all()
      |> Enum.reduce({nil, MapSet.new()}, fn
        %Annotation{step: 0, screen_id: screen_id}, {_, screen_ids} ->
          {screen_id, screen_ids}

        %Annotation{screen_id: screen_id}, {prev_screen_id, screen_ids}
        when prev_screen_id != screen_id ->
          {screen_id, MapSet.put(screen_ids, screen_id)}

        %Annotation{screen_id: screen_id}, {_, screen_ids} ->
          {screen_id, screen_ids}
      end)

    linked_screens = MapSet.union(linked_screens_edit, linked_screens_annotations)

    MapSet.difference(MapSet.new(storyline_screen_ids), linked_screens)
  end

  @doc """
  Copies multiple screens, including edits, in the same storyline and
  updates storyline last edited

  ## Examples

        iex> copy_screens(["123"], %{name: "new name", storyline_id: "567"}, actor)
        {:ok, [%Screen{name: "new name"},...]}

        iex> copy_screens(["123"], %{invalid: "option"}, actor)
        {:error, %Changeset}
  """
  def copy_screens(screen_ids, attr, actor) do
    screens = Screen.all_query(screen_ids) |> Api.Repo.all() |> Api.Repo.preload(:flow)
    [storyline_id] = screens |> Enum.map(& &1.flow.storyline_id) |> Enum.uniq()

    storyline = Storyline |> Repo.get!(storyline_id)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      result =
        Multi.new()
        |> Multi.run(:copy_screens, fn _repo, _ ->
          Copying.copy_screens(screen_ids, attr)
        end)
        |> Multi.update(:update_last_edited, update_last_edited(storyline))
        |> Repo.transaction()

      case result do
        {:ok, %{copy_screens: copy_screens}} ->
          {:ok, copy_screens}
      end
    end
  end

  @doc """
  Copies a screen, including edits, in the same storyline and updates storyline last edited

  ## Examples

        iex> copy_screen(%Screen{}, %Flow{}, %{name: "new name"})
        {:ok, %Screen{name: "new name"}}

        iex> copy_screen(%Screen{}, %Flow{}, %{invalid: "option"} )
        {:error, %Changeset}
  """
  def copy_screen(screen, flow, attr, actor) do
    flow =
      Repo.preload(flow,
        storyline: [],
        demo_version: [demo: [storyline: []]]
      )

    storyline =
      case flow do
        %Flow{storyline: %Storyline{} = storyline} -> storyline
        %Flow{demo_version: %{demo: %{storyline: %Storyline{} = storyline}}} -> storyline
      end

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      result =
        Multi.new()
        |> Multi.run(:copy_screen, fn _repo, _ ->
          Copying.copy_screen(screen, flow, attr)
        end)
        |> Multi.update(:update_last_edited, update_last_edited(flow.storyline))
        |> Repo.transaction()

      case result do
        {:ok, %{copy_screen: copy_screen}} ->
          {:ok, copy_screen}
      end
    end
  end

  @doc """
  Updates an existing style edit with a new style attributes
  and updates storyline last_edited
  """
  def update_edits(screen_id, edits, actor) do
    screen = Screen |> Repo.get!(screen_id) |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(screen.storyline, actor, :presenter) do
      Multi.new()
      |> Multi.run(:update_edits, fn _repo, _ ->
        Editing.update_edits(screen_id, edits)
      end)
      |> Multi.update(:update_last_edited, update_last_edited(screen.storyline))
      |> Repo.transaction()
    end
  end

  @doc """
  Adds multiple edits one by one and updates storyline last updated
  """
  def add_edits(screen_id, edits, actor) do
    screen = Screen |> Repo.get!(screen_id) |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(screen.storyline, actor, :presenter) do
      result =
        Multi.new()
        |> Multi.run(:add_edits, fn _repo, _ ->
          Editing.add_edits(screen_id, edits)
        end)
        |> Multi.update(:update_last_edited, update_last_edited(screen.storyline))
        |> Repo.transaction()

      case result do
        {:ok, %{add_edits: added_edits}} ->
          {:ok, added_edits}
      end
    end
  end

  @doc """
  Call ScreenGrouping.move_screen/3 with authorization.
  """
  def move_screen(screen_id, target_flow_id, new_position, actor) do
    flow_screen =
      FlowScreen
      |> Repo.get_by!(screen_id: screen_id)
      |> Repo.preload(flow: [storyline: []])

    with :ok <- Api.Authorizer.authorize(flow_screen.flow.storyline, actor, :presenter) do
      ScreenGrouping.move_screen(screen_id, target_flow_id, new_position)
    end
  end

  defp update_last_edited(storyline) do
    storyline |> Storyline.last_edited_changeset(%{last_edited: DateTime.utc_now()})
  end

  @doc """
  Call ScreenGrouping.create_flow/3 with authorization.

  ## Examples

      iex> create_flow(storyline_id, valid_attrs, actor)
      {:ok, %Flow{}}

      iex> create_flow(storyline_id, valid_attrs, bad_actor)
      {:ok, :unauthorized}
  """
  def create_flow(storyline_id, attrs, actor) do
    storyline = Storyline |> Repo.get!(storyline_id)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      ScreenGrouping.create_flow(storyline.id, attrs)
    end
  end

  def authorize_many(ids, relationship, actor) do
    res =
      Storyline
      |> where([s], s.id in ^ids)
      |> Repo.all()
      |> Enum.map(&{&1.id, Api.Authorizer.authorize(&1, actor, relationship)})
      |> Enum.into(%{})

    ids |> Enum.map(&(res[&1] || {:error, :unauthorized}))
  end
end
