defmodule Api.Storylines.Demos do
  @moduledoc """
  The Demos context.
  """

  import Ecto.Query, warn: false
  alias Api.Annotations
  alias Api.Repo
  alias Api.Storylines.Demos.{Demo, DemoVersion, StableDemoData}
  alias Api.Storylines.Editing
  alias Api.Storylines.Editing.Edit.Binding
  alias Api.Storylines.Storyline
  alias Ecto.Multi

  @doc """
  Returns the list of demos per company.

  ## Examples

      iex> list_all_demos(company_id, member_id)
      [%Demo{}, ...]

  """
  def list_all_demos(company_id, member_id) do
    Demo.all_demos_query(company_id, member_id) |> Repo.all()
  end

  @doc """
  Returns the list of demos per storyline.

  ## Examples

      iex> list_demos(storyline_id, actor)
      {:ok, [%Demo{}, ...]}

      iex> list_demos(storyline_id, bad_actor)
      {:error, :unauthorized}

  """
  def list_demos(storyline_id, actor) do
    storyline = Storyline |> Repo.get!(storyline_id)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
      {:ok, Demo.by_storyline_id_query(storyline_id) |> Repo.all()}
    end
  end

  @doc """
  Gets a single demo with preload options

  Raises `Ecto.NoResultsError` if the Demo does not exist.

  ## Examples

      iex> get_demo!(123)
      %Demo{}

      iex> get_demo!(456)
      ** (Ecto.NoResultsError)

  """

  def get_demo!(demo_id, opts \\ %{}) do
    preload =
      opts
      |> Map.get(:preload, [])

    Repo.get!(Demo, demo_id)
    |> Repo.preload(preload)
  end

  @doc """
  Gets a single demo with preload options

  ## Examples

      iex> fetch_demo(123, actor)
      {:ok, %Demo{}}

      iex> fetch_demo(123, bad_actor)
      {:error, :unauthorized}

      iex> fetch_demo(456, bad_actor)
      {:error, :not_found}

  """

  def fetch_demo(demo_id, actor) do
    with {:ok, demo} <- Demo |> Repo.fetch(demo_id),
         :ok <- Api.Authorizer.authorize(demo, actor, :viewer) do
      {:ok, demo}
    end
  end

  @doc """
  Gets an active demo version for a demo

  Raises `Ecto.NoResultsError` if the Demo does not exist.

  ## Examples

      iex> get_active_demo_version!(123)
      %DemoVersion{}

      iex> get_active_demo_version!(456)
      ** (Ecto.NoResultsError)

  """
  def get_active_demo_version!(id) do
    demo = Repo.get!(Demo, id) |> Api.Repo.preload([:active_version])
    demo.active_version
  end

  @doc """
  Creates a demo and a demo version

  ## Examples

      iex> create_demo(storyline_id, valid_attrs, actor, variables)
      {:ok, {demo: %Demo{}, demo_version: %DemoVersion{}}}

      iex> create_demo(storyline_id, invalid_attrs, actor, variables)
      {:error, %Ecto.Changeset{}}

  """
  def create_demo(storyline_id, attrs, actor, variables \\ []) do
    storyline = Api.Storylines.get_storyline!(storyline_id)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      created_by_id = actor.id

      result =
        Multi.new()
        |> Multi.insert(:inchoate_demo_version, fn _ ->
          %DemoVersion{created_by_id: created_by_id, start_screen_id: storyline.start_screen_id}
          |> DemoVersion.changeset(%{})
        end)
        |> Multi.insert(:demo, fn %{inchoate_demo_version: inchoate_demo_version} ->
          %Demo{storyline_id: storyline_id, active_version_id: inchoate_demo_version.id}
          |> Demo.changeset(attrs)
        end)
        |> Multi.update(:demo_version, fn %{
                                            inchoate_demo_version: inchoate_demo_version,
                                            demo: demo
                                          } ->
          DemoVersion.update_demo_id_changeset(inchoate_demo_version, %{demo_id: demo.id})
        end)
        |> Multi.run(:patches, fn _repo, %{demo: demo} ->
          patches = Api.Patching.list_storyline_patches(storyline_id)
          Api.Patching.add_patches(demo, patches, actor)
        end)
        |> Multi.run(:flows, fn _repo, %{demo: demo} ->
          Api.Storylines.copy_flows(storyline_id, demo)
        end)
        |> Multi.run(:update_binding_edits, fn _repo, %{flows: copied_flows} ->
          edits =
            copied_flows
            |> Enum.filter(&match?({{:copied_screen, _id}, _}, &1))
            |> Enum.flat_map(fn {{:copied_screen, _id},
                                 %{to_screen: %{id: to_screen_id} = _to_screen}} ->
              Editing.list_edits_screen_by_kind(to_screen_id, :binding)
            end)

          Binding.update_binding_edits_with_variables(variables, edits)
        end)
        |> Multi.run(:guides, fn _repo, %{demo: demo, flows: copied_flows} ->
          Annotations.copy_guides(storyline_id, demo, copied_flows)
        end)
        |> Multi.run(:settings, fn _repo, %{demo: demo} ->
          Api.Settings.copy_storyline_settings(storyline_id, demo)
        end)
        |> Repo.transaction(timeout: 20_000)

      case result do
        {:ok, %{demo_version: demo_version, demo: demo}} ->
          {:ok, %{demo_version: demo_version, demo: demo}}

        {:error, _demo, error, _att} ->
          {:error, error}
      end
    end
  end

  @doc """
  Creates a new demo version and setting it as the active_version for the demo

  ## Examples

      iex> create_new_demo_version(storyline_id, demo_id, valid_attrs, actor, variables)
      {:ok, {demo: %Demo{}, demo_version: %DemoVersion{}}}

      iex> create_new_demo_version(storyline_id, demo_id, valid_attrs, invalid_actor, variables)
      {:ok, :unauthorized}

      iex> create_new_demo_version(storyline_id, demo_id, invalid_attrs, actor, variables)
      {:error, %Ecto.Changeset{}}

  """
  def create_new_demo_version(storyline_id, demo_id, attrs, actor, variables \\ []) do
    storyline = Api.Storylines.get_storyline!(storyline_id)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      created_by_id = actor.id

      result =
        Multi.new()
        |> Multi.insert(:demo_version, fn _ ->
          %DemoVersion{start_screen_id: storyline.start_screen_id, created_by_id: created_by_id}
          |> DemoVersion.changeset(attrs)
          |> DemoVersion.update_demo_id_changeset(%{demo_id: demo_id})
        end)
        |> Multi.update(:demo, fn %{demo_version: demo_version} ->
          attrs = attrs |> Map.put(:active_version_id, demo_version.id)

          get_demo!(demo_id)
          |> Demo.update_version_changeset(attrs)
        end)
        |> Multi.run(:patches, fn _repo, %{demo: demo} ->
          patches = Api.Patching.list_storyline_patches(storyline_id)
          Api.Patching.add_patches(demo, patches, actor)
        end)
        |> Multi.run(:flows, fn _repo, %{demo: demo} ->
          Api.Storylines.copy_flows(storyline_id, demo)
        end)
        |> Multi.run(:update_binding_edits, fn _repo, %{flows: copied_flows} ->
          edits =
            copied_flows
            |> Enum.filter(&match?({{:copied_screen, _id}, _}, &1))
            |> Enum.flat_map(fn {{:copied_screen, _id},
                                 %{to_screen: %{id: to_screen_id} = _to_screen}} ->
              Editing.list_edits_screen_by_kind(to_screen_id, :binding)
            end)

          Binding.update_binding_edits_with_variables(variables, edits)
        end)
        |> Multi.run(:guides, fn _repo, %{demo: demo, flows: copied_flows} ->
          Annotations.copy_guides(storyline_id, demo, copied_flows)
        end)
        |> Multi.run(:settings, fn _repo, %{demo: demo} ->
          Api.Settings.copy_storyline_settings(storyline_id, demo)
        end)
        |> Multi.run(:update_latest_demo_version, fn _repo, %{demo: demo} ->
          with :ok <- StableDemoData.update_latest_demo_version(demo.id, demo.active_version_id) do
            {:ok, nil}
          end
        end)
        |> Repo.transaction(timeout: 50_000)

      case result do
        {:ok, %{demo_version: demo_version, demo: demo}} ->
          {:ok, %{demo_version: demo_version, demo: demo}}

        {:error, _demo, error, _att} ->
          {:error, error}
      end
    end
  end

  def update_start_screen(%Demo{id: demo_id}, attrs) do
    demo_version = get_active_demo_version!(demo_id)
    DemoVersion.update_start_screen(demo_version, attrs)
  end

  @doc """
  Updates a Demo's name

  ## Examples

      iex> rename_demo(demo_id, valid_name, actor)
      {:ok, %Demo{}}

      iex> rename_demo(demo_id, valid_name, bad_actor)
      {:error, :unauthorized}

      iex> rename_demo(demo_id, nil, actor)
      {:error, %Ecto.Changeset{}}

  """
  def rename_demo(demo_id, name, actor) do
    demo = get_demo!(demo_id) |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(demo.storyline, actor, :presenter) do
      demo
      |> Demo.rename_changeset(%{name: name})
      |> Repo.update()
    end
  end

  @doc """
  Updates a Demo's last played field

  ## Examples

      iex> update_last_played(demo_id)
      {:ok, %Demo{}}

  """
  def update_last_played(demo_id) do
    get_demo!(demo_id)
    |> Demo.last_played_changeset(%{last_played: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Updates a Demo's sharing attribute
  ## Examples
      iex> update_is_shared(demo_id, true, actor)
      {:ok, %Demo{}}

      iex> update_is_shared(demo_id, true, bad_actor)
      {:ok, :unauthorized}

      iex> update_is_shared(demo_id, false, actor)
      {:ok, %Demo{}}
  """
  def update_is_shared(demo_id, is_shared, actor) do
    demo = get_demo!(demo_id) |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(demo.storyline, actor, :presenter) do
      demo
      |> Demo.update_changeset(%{is_shared: is_shared})
      |> Repo.update()
    end
  end
end
