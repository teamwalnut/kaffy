defmodule Api.Dataloader do
  @moduledoc """
  Helper functions for Dataloader to fetch data more efficiently,
  this is outside of any context as it's ultimatly a web concern -
  But it can't be in the web layer as it requires intimite knowledge of the data structure.
  """
  alias Api.Patching.Patch
  alias Api.Repo
  alias Api.Annotations.{Annotation, Guide}
  alias Api.Storylines.Screen
  alias Api.Storylines.ScreenGrouping.{Flow, FlowScreen}
  alias Api.Storylines.SmartObjects
  import Ecto.Query

  def data(:storyline) do
    Dataloader.Ecto.new(Api.Repo, query: &query/2, run_batch: &run_batch/5)
  end

  def data(_) do
    Dataloader.Ecto.new(Api.Repo, query: &query/2)
  end

  def query(Flow, _args) do
    Flow.by_position_query()
    |> preload(flow_screens: ^FlowScreen.order_by_position_query())
  end

  def query(Patch, _args) do
    Patch.all_patches_query()
  end

  def query(Screen, _args) do
    Screen.all_query()
  end

  def query(Annotation, _args) do
    from(annotation in Annotation, order_by: [asc: annotation.step])
  end

  def query(SmartObjects.Class, _args) do
    from(smart_object in Api.Storylines.SmartObjects.Class,
      order_by: [desc: smart_object.inserted_at]
    )
  end

  def query(Api.Companies.MemberInvite, _args) do
    from(member_invite in Api.Companies.MemberInvite, order_by: [desc: member_invite.inserted_at])
  end

  def query(Api.Storylines.Editing.Edit, _args) do
    from(edit in Api.Storylines.Editing.Edit, order_by: [asc: edit.last_edited_at])
  end

  def query(Api.Storylines.Demos.Demo, _args) do
    from(demo in Api.Storylines.Demos.Demo, order_by: [desc: demo.updated_at])
  end

  def query(Guide, _args) do
    Guide.by_priority_query()
  end

  def query(queryable, %{queried_fields: queried_fields}) do
    query_fields(queryable, queried_fields)
  end

  def query(queryable, _args) do
    queryable
  end

  def run_batch(_repo, query, :screens_count, storylines, repo_opts) do
    storylines_ids = Enum.map(storylines, & &1.id)
    default_count = 0

    result =
      query
      |> Screen.count_by_storylines_query(storylines_ids)
      |> Repo.all(repo_opts)
      |> Map.new()

    for %{id: id} <- storylines do
      [Map.get(result, id, default_count)]
    end
  end

  def run_batch(_repo, query, :demo_version_screens_count, demo_versions, repo_opts) do
    demo_version_ids = Enum.map(demo_versions, & &1.id)
    default_count = 0

    result =
      query
      |> FlowScreen.count_by_demo_versions_query(demo_version_ids)
      |> Repo.all(repo_opts)
      |> Map.new()

    for %{id: id} <- demo_versions do
      [Map.get(result, id, default_count)]
    end
  end

  defp query_fields(module, fields) do
    # this does intersection with the schema fields, couldnt find an easier way
    fields = module.__schema__(:fields) -- module.__schema__(:fields) -- fields
    from(module, select: ^fields)
  end
end
