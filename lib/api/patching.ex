defmodule Api.Patching do
  @moduledoc """
  Patching is a way to alter each screen inside a storyline with different alternations to the HTML.
  A Patch is very similar to an Edit, but unlike Edits that represent an edit by our users, a Patch is a way to
  alter the HTML to fix various issues:
  - Our current capture mechanism doesnt save Scroll Position, we currently apply them as Edits, but they're actually a patch.
  - We dont have access to some content, like if we try to capture chrome extension injected_css, we'll not capture it, as such we can add this css via a patch.
  """
  alias Api.Companies.Company
  alias Api.Patching.Patch
  alias Api.Repo
  alias Api.Storylines.Demos
  alias Api.Storylines.Demos.Demo
  alias Api.Storylines.Demos.DemoVersion
  alias Api.Storylines.Storyline

  @doc """
  Gets a patch by the id

  ## Examples

      iex> get_patch("patch_uuid")
      {:ok, %Api.Patching.Patch{}}
  """
  def get_patch!(id), do: Repo.get!(Patch, id)

  @doc """
  Adds a patch to a company.

  ## Examples

      iex> add_company_patch("company_uuid", %Api.Patching.HtmlPatch{...}, "patch_name", actor)
      {:ok, %Api.Patching.Patch{}}

      iex> add_company_patch("company_uuid", %Api.Patching.HtmlPatch{...}, "patch_name", bad_actor)
      {:error, :unauthorized}
  """
  def add_company_patch(company_id, %Api.Patching.HtmlPatch{} = data, name, actor) do
    with {:ok, company} <- Repo.fetch(Company, company_id),
         :ok <- Api.Authorizer.authorize(company, actor, :admin) do
      %Patch{data: data}
      |> Patch.create_changeset(%{company_id: company_id, name: name})
      |> Repo.insert()
    end
  end

  def add_company_patch(company_id, data, name, actor) when is_map(data) do
    with {:ok, company} <- Repo.fetch(Company, company_id),
         :ok <- Api.Authorizer.authorize(company, actor, :admin) do
      %Patch{}
      |> Patch.create_changeset(%{data: data, company_id: company_id, name: name})
      |> Repo.insert()
    end
  end

  @doc """
  Returns a list of all patches for a given company id.

  ## Examples

      iex> list_company_patches("company_uuid")
      [%Api.Patching.HtmlPatch{}]
  """
  def list_company_patches(company_id) do
    Patch.by_company_id_query(company_id) |> Repo.all()
  end

  @doc """
  Adds a patch to a storyline.

  ## Examples

      iex> add_storyline_patch("storyline_uuid", %Api.Patching.HtmlPatch{...}, "patch_name", actor)
      {:ok, %Api.Patching.Patch{}}

      iex> add_storyline_patch("storyline_uuid", %Api.Patching.HtmlPatch{...}, "patch_name", bad_actor)
      {:error, :unauthorize}
  """
  def add_storyline_patch(storyline_id, %Api.Patching.HtmlPatch{} = data, name, actor) do
    with {:ok, storyline} <- Repo.fetch(Storyline, storyline_id),
         :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      %Patch{data: data}
      |> Patch.create_changeset(%{storyline_id: storyline_id, name: name})
      |> Repo.insert()
    end
  end

  def add_storyline_patch(storyline_id, data, name, actor) when is_map(data) do
    with {:ok, storyline} <- Repo.fetch(Storyline, storyline_id),
         :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      %Patch{}
      |> Patch.create_changeset(%{data: data, storyline_id: storyline_id, name: name})
      |> Repo.insert()
    end
  end

  @doc """
  Adds a patch to a demo

  ## Examples

      iex> add_storyline_patch("demo_uuid", %Api.Patching.HtmlPatch{...}, "patch_name")
      {:ok, %Api.Patching.Patch{}}
  """
  def add_demo_patch(demo_id, %Api.Patching.HtmlPatch{} = data, name) do
    demo_version = Demos.get_active_demo_version!(demo_id)

    %Patch{data: data}
    |> Patch.create_changeset(%{demo_version_id: demo_version.id, name: name})
    |> Repo.insert()
  end

  def add_demo_patch(demo_id, data, name) when is_map(data) do
    demo_version = Demos.get_active_demo_version!(demo_id)

    %Patch{}
    |> Patch.create_changeset(%{data: data, demo_version_id: demo_version.id, name: name})
    |> Repo.insert()
  end

  @doc """
  Returns a list of all patches for a given storyline id.

  ## Examples

      iex> list_storyline_patches("storyline_id")
      [%Api.Patching.HtmlPatch{}]

  """
  def list_storyline_patches(storyline_id) do
    Patch.by_storyline_id_query(storyline_id) |> Repo.all()
  end

  @doc """
  Helper function to copy multiple Patches to a Storyline.
  Takes a list of %Api.Patching.Patch and adds them to the given storyline

  ## Examples

      iex> add_patches(%Storyline{}, [%Patch{...}, %Patch{...}], actor)
      {:ok, [%Patch{...}, %Patch{...}]}

      iex> add_patches(%Storyline{}, [%Patch{...}, %Patch{...}], bad_actor)
      {:error, :unauthorized}
  """
  def add_patches(%Storyline{} = storyline, patches, actor) do
    added_patches =
      patches
      |> Enum.map(fn patch ->
        Api.Patching.add_storyline_patch(storyline.id, patch.data, patch.name, actor)
      end)

    case added_patches |> Enum.filter(&(&1 |> elem(1) == :error)) do
      [] -> {:ok, added_patches}
      error_patches -> {:error, error_patches}
    end
  end

  def add_patches(%Demo{} = demo, patches, _actor) do
    added_patches =
      patches
      |> Enum.map(fn patch ->
        Api.Patching.add_demo_patch(demo.id, patch.data, patch.name)
      end)

    case added_patches |> Enum.filter(&(&1 |> elem(1) == :error)) do
      [] -> {:ok, added_patches}
      error_patches -> {:error, error_patches}
    end
  end

  @doc """
  Updates a patch to a Storyline.
  Takes a struct with the html patch data

  ## Examples

      iex> update_patch(%Patch{...}, %{}], actor)
      {:ok, %Api.Patching.Patch{}}

      iex> update_patch(%Patch{...}, %{}], bad_actor)
      {:error, :unauthorized}
  """
  def update_patch(%Patch{} = patch, new_patch_data, actor) do
    resource = get_related_authorization_resource_from_patch(patch)

    authorization =
      case resource do
        %Storyline{} = storyline -> Api.Authorizer.authorize(storyline, actor, :presenter)
        %Company{} = company -> Api.Authorizer.authorize(company, actor, :admin)
      end

    with :ok <- authorization do
      patch
      |> Patch.update_changeset(%{data: new_patch_data})
      |> Repo.update()
    end
  end

  @doc """
  Removes a patch.

  ## Examples

      iex> remove_patch(%Patch{...}, actor)
      {:ok, %Api.Patching.Patch{}}

      iex> remove_patch(%Patch{...}, bad_actor)
      {:ok, :unauthorized}
  """
  def remove_patch(%Patch{} = patch, actor) do
    resource = get_related_authorization_resource_from_patch(patch)

    authorization =
      case resource do
        %Storyline{} = storyline -> Api.Authorizer.authorize(storyline, actor, :presenter)
        %Company{} = company -> Api.Authorizer.authorize(company, actor, :admin)
      end

    with :ok <- authorization do
      patch |> Repo.delete()
    end
  end

  def get_related_authorization_resource_from_patch(%Patch{} = patch) do
    patch =
      Repo.preload(
        patch,
        company: [],
        storyline: [],
        demo_version: [demo: [storyline: []]]
      )

    case patch do
      %Patch{storyline: %Storyline{} = storyline} ->
        storyline

      %Patch{demo_version: %DemoVersion{demo: %Demo{storyline: %Storyline{} = storyline}}} ->
        storyline

      %Patch{company: %Company{} = company} ->
        company
    end
  end
end
