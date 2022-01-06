defmodule Api.Patching.Patch do
  @moduledoc false
  use Api.Schema

  import PolymorphicEmbed, only: [cast_polymorphic_embed: 2]

  alias Api.Patching.Patch

  @type_map [
    html_patch: Api.Patching.HtmlPatch
  ]
  schema "patches" do
    field :name, :string

    field :data, PolymorphicEmbed,
      types: @type_map,
      on_replace: :update,
      on_type_not_found: :raise

    belongs_to :company, Api.Companies.Company
    belongs_to :storyline, Api.Storylines.Storyline
    belongs_to :demo_version, Api.Storylines.Demos.DemoVersion
    timestamps()
  end

  @doc false
  def create_changeset(%Patch{} = patch, attrs \\ %{}) do
    patch
    |> cast(attrs, [:company_id, :storyline_id, :demo_version_id, :name])
    |> cast_polymorphic_embed(:data)
    |> validate_required([:data, :name])
    |> validate_required_inclusion([:company_id, :storyline_id, :demo_version_id])
    |> assoc_constraint(:company)
    |> assoc_constraint(:storyline)
    |> assoc_constraint(:demo_version)
  end

  @doc false
  def update_changeset(%Patch{} = patch, attrs) do
    patch
    |> cast(attrs, [])
    |> cast_polymorphic_embed(:data)
    |> validate_required([:data])
  end

  def by_company_id_query(company_id) do
    from(patches in all_patches_query(),
      where: patches.company_id == ^company_id
    )
  end

  def by_storyline_id_query(storyline_id) do
    from(patches in all_patches_query(),
      where: patches.storyline_id == ^storyline_id
    )
  end

  def all_patches_query do
    from(patch in __MODULE__, order_by: [asc: patch.inserted_at])
  end
end
