defmodule Api.StorylineCreation do
  @moduledoc """
  Handles storyline creation
  """
  require Logger
  alias Api.Patching
  alias Api.Repo
  alias Api.Storylines
  alias Ecto.Multi

  @doc """
  Creates a public storyline, appends company patches and creates a default flow

  ## Examples

      iex> create_public_storyline(%{field: value}, actor)
      {:ok, %Storyline{}}

      iex> create_public_storyline(%{field: bad_value}, actor)
      {:error, %Ecto.Changeset{}}

  """
  def create_public_storyline(attrs \\ %{}, actor) do
    load_company_patches_multi(actor)
    |> Multi.run(:storyline, fn _repo, _ ->
      Storylines.create_public_storyline(attrs, actor)
    end)
    |> Multi.run(:storyline_patches, fn _repo,
                                        %{company_patches: company_patches, storyline: storyline} ->
      Patching.add_patches(storyline, company_patches, actor)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{storyline: storyline}} -> {:ok, storyline}
      {:error, _, error, _} -> {:error, error}
    end
  end

  @doc """
  Creates a private storyline, appends company patches and creates a default flow

  ## Examples

      iex> create_private_storyline(%{field: value}, actor)
      {:ok, %Storyline{}}

      iex> create_private_storyline(%{field: bad_value}, actor)
      {:error, %Ecto.Changeset{}}

      iex> create_private_storyline(%{field: value}, actor)
      {:error, :unauthorized}

  """
  def create_private_storyline(attrs, actor) do
    load_company_patches_multi(actor)
    |> Multi.run(:storyline, fn _repo, _ ->
      Api.Storylines.create_private_storyline(attrs, actor)
    end)
    |> Multi.run(:storyline_patches, fn _repo,
                                        %{company_patches: company_patches, storyline: storyline} ->
      Patching.add_patches(storyline, company_patches, actor)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{storyline: storyline}} -> {:ok, storyline}
      {:error, :storyline, :unauthorized, _} -> {:error, :unauthorized}
    end
  end

  defp load_company_patches_multi(member) do
    Multi.new()
    |> Multi.run(:company, fn _repo, _ ->
      {:ok, Api.Companies.get_company!(member.company_id)}
    end)
    |> Multi.run(:company_patches, fn _repo, %{company: company} ->
      {:ok, Api.Patching.list_company_patches(company.id)}
    end)
  end
end
