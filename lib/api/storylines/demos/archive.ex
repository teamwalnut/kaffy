defmodule Api.Storylines.Demos.Archive do
  @moduledoc """
  This module handling archived demos,
  An archive demo currently behaves similarly to archive storyline.
  """
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Storylines.Demos.Demo
  alias Api.Storylines.Storyline

  @doc """
  Marks a demo as archived, set archive date with value
  """
  def archive(%Demo{} = demo, actor) do
    demo = demo |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(demo.storyline, actor, :presenter) do
      demo |> Demo.update_changeset(%{archived_at: DateTime.utc_now()}) |> Repo.update()
    end
  end

  @doc """
  Restore demo , set archive date to null
  """
  def restore(%Demo{archived_at: archived_at} = demo, actor) when not is_nil(archived_at) do
    demo = demo |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(demo.storyline, actor, :presenter) do
      demo |> Demo.update_changeset(%{archived_at: nil}) |> Repo.update()
    end
  end

  @doc """
  Lists all archived demos per company
  """
  def list_all_demos(company_id, member_id) do
    Demo.archived_query(company_id, member_id) |> Repo.all()
  end

  @doc """
  Lists all archived demos of the storyline
  """
  def list_demos(storyline_id, actor) do
    storyline = Storyline |> Repo.get!(storyline_id)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
      demos =
        Demo.archived_by_storyline_id_query(storyline_id)
        |> Repo.all()

      {:ok, demos}
    end
  end
end
