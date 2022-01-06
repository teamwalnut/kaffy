defmodule ApiWeb.Schema.AnnotationTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers
  alias ApiWeb.Middlewares

  enum :anchor do
    values(Ecto.Enum.values(Api.Annotations.Annotation, :anchor))
  end

  enum :annotation_kind do
    values(Ecto.Enum.values(Api.Annotations.Annotation, :kind))
  end

  @desc """
  A guide is a collection of annotations ordered linearly per a Storyline.
  """
  object :guide do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:priority, non_null(:integer))

    field(:annotations, non_null(list_of(non_null(:annotation))), resolve: dataloader(:annotation))
  end

  object :rich_text do
    field(:as_json, :string,
      resolve: fn rich_text, _, _ ->
        Jason.encode(rich_text)
      end
    )
  end

  @desc """
  An annotation is a piece of information anchored to an element in a screen - point annotation,
  or the whole screen - modal annotation.
  """
  object :annotation do
    field(:id, non_null(:id))
    field(:kind, non_null(:annotation_kind))
    field(:message, non_null(:string))
    field(:rich_text, :rich_text)
    field(:screen_id, non_null(:id))
    field(:css_selector, :string)
    field(:frame_selectors, list_of(non_null(:string)))
    field(:step, non_null(:integer))
    field(:anchor, :anchor)

    field(:has_overlay, non_null(:boolean),
      deprecate:
        "The old way we used to know if to show/hide the dim behind the annotation. We now use the :show_dim field inside the settings jsonb column."
    ) do
      resolve(fn annotation, _, _ ->
        # note(@pazaricha): The reason we default to false in case there is no value in the settings.show_dim
        # is because that that was the default value of the has_overlay column on the db.
        {:ok, annotation.settings.show_dim || false}
      end)
    end

    field(:settings, non_null(:annotation_settings))
  end

  object :point do
    field(:id, non_null(:id))
    field(:kind, non_null(:annotation_kind))
    field(:message, non_null(:string))
    field(:rich_text, :rich_text)
    field(:screen_id, non_null(:id))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:anchor, non_null(:anchor))
    field(:settings, non_null(:annotation_settings))
  end

  object :modal do
    field(:id, non_null(:id))
    field(:kind, non_null(:annotation_kind))
    field(:message, non_null(:string))
    field(:rich_text, :rich_text)
    field(:screen_id, non_null(:id))
    field(:settings, non_null(:annotation_settings))
  end

  object :annotation_mutations do
    @desc "Adds a modal annotation to guide"
    field :add_modal_annotation_to_guide, :modal do
      middleware(Middlewares.AuthnRequired)
      arg(:guide_id, non_null(:id))
      arg(:message, :string)
      arg(:rich_text_as_json, :string)

      arg(:has_overlay, :boolean,
        deprecate:
          "The old way we used to know if to show/hide the dim behind the annotation. We now use the :show_dim field inside the settings jsonb column."
      )

      arg(:screen_id, non_null(:id))
      arg(:step, :integer)
      arg(:settings, :annotation_settings_input)

      resolve(fn _parent, %{guide_id: guide_id} = args, %{context: %{current_member: actor}} ->
        args = resolve_rich_text(args)

        case Api.Annotations.add_annotation_to_guide(guide_id, args, :modal, actor) do
          {:ok, %{"create_annotation" => added_annotation}} ->
            add_annotation_success(actor.user, guide_id, added_annotation)

          {:ok, added_annotation} ->
            add_annotation_success(actor.user, guide_id, added_annotation)

          other ->
            other
        end
      end)
    end

    @desc "Adds a point annotation to guide"
    field :add_point_annotation_to_guide, :point do
      middleware(Middlewares.AuthnRequired)
      arg(:guide_id, non_null(:id))
      arg(:message, :string)
      arg(:rich_text_as_json, :string)
      arg(:screen_id, non_null(:id))
      arg(:css_selector, non_null(:string))
      arg(:frame_selectors, list_of(non_null(:string)))
      arg(:anchor, non_null(:anchor))

      arg(:has_overlay, :boolean,
        deprecate:
          "The old way we used to know if to show/hide the dim behind the annotation. We now use the :show_dim field inside the settings jsonb column."
      )

      arg(:step, :integer)
      arg(:settings, :annotation_settings_input)

      resolve(fn _parent, %{guide_id: guide_id} = args, %{context: %{current_member: actor}} ->
        args = resolve_rich_text(args)

        case Api.Annotations.add_annotation_to_guide(guide_id, args, :point, actor) do
          {:ok, %{"create_annotation" => added_annotation}} ->
            add_annotation_success(actor.user, guide_id, added_annotation)

          {:ok, added_annotation} ->
            add_annotation_success(actor.user, guide_id, added_annotation)

          err ->
            err
        end
      end)
    end

    @desc "Updates an annotation"
    field :update_annotation, non_null(:annotation) do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))
      arg(:kind, :annotation_kind)
      arg(:message, :string)
      arg(:rich_text_as_json, :string)
      arg(:screen_id, :id)
      arg(:css_selector, :string)
      arg(:frame_selectors, list_of(non_null(:string)))
      arg(:anchor, :anchor)

      arg(:has_overlay, :boolean,
        deprecate:
          "The old way we used to know if to show/hide the dim behind the annotation. We now use the :show_dim field inside the settings jsonb column."
      )

      arg(:settings, :annotation_settings_input)

      resolve(fn _parent, %{id: id} = args, %{context: %{current_member: actor}} ->
        annotation = Api.Annotations.get_annotation!(id)
        args = resolve_rich_text(args)

        with {:ok, %{guide_id: guide_id} = updated_annotation} <-
               Api.Annotations.update_annotation(annotation, args, actor) do
          ApiWeb.Analytics.report_annotation_updated(actor.user, guide_id, updated_annotation)
          {:ok, updated_annotation}
        end
      end)
    end

    @desc "Deletes an annotation"
    field :delete_annotation, non_null(:annotation) do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))

      resolve(fn _parent, %{id: id}, %{context: %{current_member: actor}} ->
        annotation = Api.Annotations.get_annotation!(id)

        with {:ok, %{guide_id: guide_id} = deleted_annotation} <-
               Api.Annotations.delete_annotation(annotation, actor) do
          ApiWeb.Analytics.report_annotation_deleted(actor.user, guide_id, deleted_annotation)
          {:ok, deleted_annotation}
        end
      end)
    end

    @desc "Repositions an annotation"
    field :reposition_annotation, non_null(:annotation) do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))
      arg(:step, non_null(:integer))

      resolve(fn _parent,
                 %{id: annotation_id, step: new_position},
                 %{context: %{current_member: actor}} ->
        with {:ok, _annotations} <-
               Api.Annotations.reposition_annotation(annotation_id, new_position, actor) do
          annotation = Api.Annotations.get_annotation!(annotation_id)
          {:ok, annotation}
        end
      end)
    end

    @desc "Creates a guide for a storyline"
    field :create_guide, non_null(:guide) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:name, non_null(:string))

      resolve(fn _parent,
                 %{storyline_id: storyline_id, name: name},
                 %{context: %{current_member: actor}} ->
        with {:ok, created_guide} <-
               Api.Annotations.create_guide(storyline_id, %{name: name}, actor) do
          ApiWeb.Analytics.report_guide_created(actor.user, storyline_id, created_guide)
          {:ok, created_guide}
        end
      end)
    end

    @desc "Deletes a guide"
    field :delete_guide, non_null(:guide) do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))

      resolve(fn _parent, %{id: id}, %{context: %{current_member: actor}} ->
        guide = Api.Annotations.get_guide!(id)

        with {:ok, %{delete_guide: deleted_guide}} <- Api.Annotations.delete_guide(guide, actor) do
          ApiWeb.Analytics.report_guide_deleted(actor.user, deleted_guide)
          {:ok, deleted_guide}
        end
      end)
    end

    @desc "Renames a guide"
    field :rename_guide, non_null(:guide) do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))
      arg(:name, non_null(:string))

      resolve(fn _parent, %{id: id, name: name}, %{context: %{current_member: actor}} ->
        guide = Api.Annotations.get_guide!(id)

        with {:ok, renamed_guide} <- Api.Annotations.rename_guide(guide, name, actor) do
          ApiWeb.Analytics.report_guide_renamed(actor.user, renamed_guide)
          {:ok, renamed_guide}
        end
      end)
    end

    @desc "Repositions a guide"
    field :reposition_guide, non_null(:guide) do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))
      arg(:new_priority, non_null(:integer))

      resolve(fn _parent,
                 %{id: guide_id, new_priority: new_priority},
                 %{context: %{current_member: actor}} ->
        with {:ok, _annotations} <-
               Api.Annotations.reposition_guide(guide_id, new_priority, actor) do
          guide = Api.Annotations.get_guide!(guide_id)
          {:ok, guide}
        end
      end)
    end
  end

  defp add_annotation_success(current_user, guide_id, added_annotation) do
    ApiWeb.Analytics.report_annotation_added(current_user, guide_id, added_annotation)
    {:ok, added_annotation}
  end

  defp resolve_rich_text(args) do
    if args[:rich_text_as_json] != nil && String.length(args[:rich_text_as_json]) > 0 do
      Map.put(args, :rich_text, Jason.decode!(args[:rich_text_as_json]))
    else
      args
    end
  end
end
