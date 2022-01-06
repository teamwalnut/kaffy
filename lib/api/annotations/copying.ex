defmodule Api.Annotations.Copying do
  @moduledoc """
  Helps copying entities related to annotations.
  Please read each method documentation
  """
  alias Api.Annotations
  alias Api.Annotations.{Annotation, Guide}
  alias Api.Repo
  alias Api.Storylines.{Demos, Storyline}
  alias Api.Storylines.Demos.Demo
  alias Ecto.Multi

  @doc """
  Deep-Copies all the guides from a storyline into the passed target, including copying all the guides annotations
  This function can only works when passed with `copied_flows` which comes from other places in the code where we copy a storyline or create a demo.
  Please take a look where this function is being called to understand more.
  """
  def copy_guides(storyline_id, target, copied_flows) do
    guides = Annotations.list_guides(storyline_id)

    guides
    |> Enum.reduce(Multi.new(), fn guide, multi ->
      multi |> Multi.append(guide |> copy_guide_multi(target, copied_flows))
    end)
    |> Repo.transaction()
  end

  defp copy_guide_multi(%Guide{} = origin_guide, target, copied_flows) do
    origin_guide = origin_guide |> Repo.preload(annotations: [])
    origin_annotations = origin_guide.annotations
    copied_guide_key = {:copied_guide, origin_guide.id}

    multi =
      Multi.new()
      # First we copy the guide
      |> Multi.run(copied_guide_key, fn _repo, _changes_so_far ->
        copy_guide(origin_guide, target)
      end)

    # Next, for each annotation, we copy it
    origin_annotations
    |> Enum.reduce(multi, fn annotation, multi ->
      annotation_key = {:copied_annotation, annotation.id}

      multi
      |> Multi.run(annotation_key, fn _repo, changes_so_far ->
        copied_guide = changes_so_far |> Map.get(copied_guide_key)

        # Locate the the new screen_id this annotation should be connected to
        # credo:disable-for-lines:10 Credo.Check.Refactor.Nesting
        target_screen_id =
          copied_flows
          |> Enum.find_value(fn
            {{:copied_screen, copied_screen_id},
             %{from_screen_id: _from_screen_id, to_screen: %{id: to_screen_id} = _to_screen}} ->
              if copied_screen_id == annotation.screen_id, do: to_screen_id, else: nil

            _ ->
              nil
          end)

        copy_annotation(annotation, copied_guide.id, target_screen_id)
      end)
    end)
  end

  defp copy_guide(%Guide{} = origin_guide, %Storyline{id: storyline_id}) do
    %Guide{storyline_id: storyline_id}
    |> Guide.create_changeset(prepare_new_guide_attrs(origin_guide))
    |> Repo.insert()
  end

  defp copy_guide(%Guide{} = origin_guide, %Demo{id: demo_id}) do
    demo_version = Demos.get_active_demo_version!(demo_id)

    %Guide{demo_version_id: demo_version.id}
    |> Guide.create_changeset(prepare_new_guide_attrs(origin_guide))
    |> Repo.insert()
  end

  defp prepare_new_guide_attrs(%Guide{} = origin_guide) do
    fields_to_copy =
      Guide.__schema__(:fields)
      |> Enum.filter(fn field ->
        field not in [:id, :inserted_at, :updated_at, :storyline_id, :demo_version_id]
      end)

    origin_guide |> Map.from_struct() |> Map.take(fields_to_copy)
  end

  defp copy_annotation(%Annotation{} = origin_annotation, target_guide_id, target_screen_id) do
    fields_to_copy =
      Annotation.__schema__(:fields)
      |> Enum.filter(fn field ->
        field not in [:id, :inserted_at, :updated_at, :guide_id, :screen_id, :kind]
      end)

    new_annotation_attributes =
      origin_annotation
      |> Map.from_struct()
      |> Map.take(fields_to_copy)
      |> Map.put(:screen_id, target_screen_id)
      |> Map.put(:settings, Map.from_struct(origin_annotation.settings))

    %Annotation{guide_id: target_guide_id, kind: origin_annotation.kind}
    |> Annotation.create_changeset(new_annotation_attributes, origin_annotation.kind)
    |> Repo.insert()
  end
end
