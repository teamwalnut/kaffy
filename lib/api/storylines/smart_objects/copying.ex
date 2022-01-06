defmodule Api.Storylines.SmartObjects.Copying do
  @moduledoc """
  Helps copying entities related to smart objects.
  """
  alias Api.Repo
  alias Api.Storylines
  alias Api.Storylines.Screen
  alias Api.Storylines.SmartObjects
  alias Api.Storylines.SmartObjects.Class
  alias Api.Storylines.SmartObjects.Instance
  alias Ecto.Multi

  @doc """
  Copies the smart object classes from origin_storyline_id to the passed target
  """
  def copy_classes_and_remap_instances(origin_storyline_id, copied_storyline, copied_flows) do
    %{id: copied_storyline_id} = copied_storyline

    Multi.new()
    |> Multi.run({:copied_classes, copied_storyline_id}, fn _, _ ->
      copy_classes(origin_storyline_id, copied_storyline_id, copied_flows)
    end)
    |> Multi.merge(&remap_instances(copied_storyline_id, copied_flows, &1))
    |> Repo.transaction()
  end

  defp copy_classes(origin_storyline_id, copied_storyline_id, copied_flows) do
    {:ok, origin_classes} = SmartObjects.list_classes(origin_storyline_id)

    copied_classes =
      origin_classes
      |> Enum.map(fn class ->
        %{edits: origin_class_edits} = SmartObjects.convert_edits(class, :edits)

        new_class_edits =
          origin_class_edits
          |> Enum.map(fn edit ->
            Storylines.Copying.find_and_remap_edit_screen(edit, copied_flows)
          end)

        attrs = %{
          (class
           |> Class.to_attributes()
           |> Map.delete("id"))
          | "storyline_id" => copied_storyline_id,
            "edits" => new_class_edits
        }

        new_class =
          Class.create_changeset(%Class{}, attrs)
          |> Repo.insert!()

        %{origin_class_id: class.id, new_class: new_class}
      end)

    {:ok, copied_classes}
  end

  defp remap_instances(copied_storyline_id, copied_flows, copied_classes_map) do
    copied_flows
    |> Enum.filter(&match?({{:copied_screen, _id}, _}, &1))
    |> Enum.reduce(Multi.new(), fn {{:copied_screen, _from_id}, %{to_screen: copied_screen}},
                                   multi ->
      copied_screen = Repo.reload(copied_screen)

      multi
      |> Ecto.Multi.update({:update_instances_classes, copied_screen.id}, fn _ ->
        instances =
          remap_instances_classes(
            copied_storyline_id,
            copied_screen.smart_object_instances,
            copied_classes_map
          )
          |> Instance.to_attributes()

        Screen.update_changeset(copied_screen, %{
          smart_object_instances: instances
        })
      end)
    end)
  end

  defp remap_instances_classes(copied_storyline_id, copied_instances, copied_classes_map) do
    copied_instances
    |> Enum.map(fn
      instance ->
        new_class_id = find_new_target_class_id(copied_classes_map, instance)

        %Instance{
          instance
          | class_id: new_class_id,
            storyline_id: copied_storyline_id
        }
    end)
  end

  defp find_new_target_class_id(copied_classes_map, instance) do
    copied_classes =
      copied_classes_map
      |> Map.values()
      |> List.flatten()

    %{new_class: %{id: new_class_id} = _new_class} =
      copied_classes
      |> Enum.find(fn
        %{origin_class_id: origin_class_id, new_class: _new_class} ->
          instance.class_id == origin_class_id
      end)

    new_class_id
  end
end
