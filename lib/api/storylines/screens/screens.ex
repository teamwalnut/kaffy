defmodule Api.Storylines.Screens do
  @moduledoc false

  alias Api.Repo
  alias Api.Storylines.Screen

  def empty, do: %Screen{}

  def with_id(%Screen{} = m, id), do: %Screen{m | id: id}

  def get(id) do
    case Repo.get(Screen, id) do
      nil -> {:error, :screen_does_not_exist}
      %Screen{} = s -> {:ok, s}
    end
  end

  def update_smart_object_instances(screen, instances) do
    # NOTE(@ostera): ideally, we would only have a single `changeset/2`
    # function that we always use to validate both creation and updates of records
    Screen.create_changeset(screen, %{smart_object_instances: instances})
    |> Repo.update()
  end

  def get_all_with_instances(storyline_id) do
    Screen.all_with_instances_query(storyline_id)
    |> Repo.all()
  end
end
