defmodule Api.Annotations.Guide do
  @moduledoc """
  Represents a Guide,
  a collection of annotations ordered linearly
  per a Storyline.
  """

  use Api.Schema
  @position_index_basis 0

  schema "guides" do
    field(:name, :string)
    field(:priority, :integer)
    belongs_to :storyline, Api.Storylines.Storyline
    belongs_to :demo_version, Api.Storylines.Demos.DemoVersion
    has_many(:annotations, Api.Annotations.Annotation)

    timestamps()
  end

  @doc """
  Returns a changeset for creating a guide.
  """
  def create_changeset(guide, attrs) do
    guide
    |> cast(attrs, [:name, :priority])
    |> validate_required([:name, :priority])
    |> validate_required_inclusion([:storyline_id, :demo_version_id])
    |> validate_priority()
    |> validate_unique_priority()
  end

  @doc """
  Returns a changeset for renaming a guide.
  """
  def rename_changeset(guide, attrs) do
    guide
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  @doc """
  Returns a changeset for repositioning a guide.
  """
  def reposition_changeset(guide, attrs) do
    guide
    |> cast(attrs, [:priority])
    |> validate_priority()
    |> unique_constraint([:priority, :storyline_id, :demo_version_id],
      message: "can't have 2 guides in the same priority"
    )
  end

  def delete_changeset(guide) do
    guide |> change
  end

  defp validate_priority(changeset) do
    changeset
    |> validate_number(:priority, greater_than_or_equal_to: 0)
  end

  defp validate_unique_priority(changeset) do
    changeset
    |> unsafe_validate_unique([:priority, :storyline_id, :demo_version_id], Api.Repo,
      message: "can't have 2 guides in the same priority"
    )
    |> unique_constraint([:priority, :storyline_id, :demo_version_id],
      message: "can't have 2 guides in the same priority"
    )
  end

  @doc """
  Returns a query that returns all guides for a given storyline id
  """
  def list_query(storyline_id) do
    from guide in Api.Annotations.Guide,
      where: guide.storyline_id == ^storyline_id,
      order_by: [asc: :priority]
  end

  @doc """
  Query that returns all guides ordered by priority
  """
  def by_priority_query do
    from(guide in Api.Annotations.Guide,
      order_by: [asc: :priority]
    )
  end

  def defer_position_unique_constraint_query do
    "SET CONSTRAINTS guides_priority_storyline_id_demo_version_id DEFERRED"
  end

  def position_index_basis do
    @position_index_basis
  end
end
