defmodule Api.Storylines.Collaborator do
  @moduledoc """
  Collaborator is a connection between a %Api.Companies.Member{} and %Api.Storylines.Storyline{} allowing the given Member
  access to a specified storyline, even if the storyline is private.
  """
  use Api.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key false
  @foreign_key_type :binary_id
  schema "storylines_collaborators" do
    belongs_to :member, Api.Companies.Member
    belongs_to :storyline, Api.Storylines.Storyline
    timestamps()
  end

  @doc false
  def add_changeset(collaborator, attrs) do
    collaborator
    |> cast(attrs, [:member_id, :storyline_id])
    |> validate_required([:member_id, :storyline_id])
    |> unique_constraint([:member_id, :storyline_id],
      name: :storylines_collaborators_storyline_id_member_id_index
    )
  end

  def by_storyline_id_query(storyline_id) do
    from collaborator in __MODULE__,
      where: collaborator.storyline_id == ^storyline_id
  end

  def by_storyline_member_query(storyline_id, member_id) do
    from collaborator in __MODULE__,
      where: collaborator.storyline_id == ^storyline_id and collaborator.member_id == ^member_id
  end
end
