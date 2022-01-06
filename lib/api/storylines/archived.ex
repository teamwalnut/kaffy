defmodule Api.Storylines.Archived do
  @moduledoc """
  This module handling archived Storylines,
  An archive storyline currently behaves similarly to any other storyline except that the only way to interact with it is using
  this module.
  """
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Storylines.Storyline
  alias Ecto.Multi

  @doc """
  Marks a storyline as archived
  """
  def archive(%Storyline{} = storyline, actor) do
    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      Multi.new()
      |> Multi.update(:archived_storyline, Storyline.archive_changeset(storyline))
      |> Multi.delete_all(:collaborators, Ecto.assoc(storyline, :collaborators))
      |> Repo.transaction()
    end
  end

  def restore(%Storyline{archived_at: archived_at} = storyline, actor)
      when not is_nil(archived_at) do
    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      storyline
      |> Storyline.restore_archived_changeset()
      |> Repo.update()
    end
  end

  @doc """
  Lists all archived storyline for the current member
  """
  def list(owner_id, company_id) do
    Storyline.archived_storylines_query(owner_id, company_id) |> Repo.all()
  end
end
