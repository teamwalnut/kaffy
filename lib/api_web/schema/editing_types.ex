defmodule ApiWeb.Schema.EditingTypes do
  @moduledoc false
  require Logger
  use Absinthe.Schema.Notation
  alias Api.Storylines
  alias Api.Storylines.Editing
  alias Api.Storylines.Editing.Edit
  alias Api.Storylines.Editing.Edit.Link
  alias Api.Storylines.Editing.Edit.Link.UrlDestination
  alias ApiWeb.{GraphQLHelpers, Middlewares}
  import Absinthe.Resolution.Helpers

  enum :edit_kind do
    value(:text, description: "Text edit")
    value(:style, description: "Style edit")
    value(:html, description: "Html edit")
    value(:change_image, description: "Changing an image edit")
    value(:link, description: "Link edit")
    value(:scroll, description: "Scroll edit")
    value(:binding, description: "A dynamically bound value")
  end

  object :text_edit_props do
    field(:original_text, non_null(:string))
    field(:text, non_null(:string))
  end

  input_object :new_text_edit_props do
    field(:original_text, non_null(:string))
    field(:text, non_null(:string))
  end

  object :binding_edit_props do
    field(:original_text, non_null(:string))
    field(:program, non_null(:string), resolve: &binding_edit_program_resolver/3)
  end

  input_object :new_binding_edit_props do
    field(:original_text, non_null(:string))
    field(:program, non_null(:string))
  end

  object :style_edit_props do
    field(:underline, :boolean)
    field(:bold, :boolean)
    field(:hide, :boolean)
    field(:font_size, :string)
    field(:color, :string)
  end

  object :html_edit_props do
    field(:value, non_null(:string))
    field(:original_value, non_null(:string))
  end

  input_object :new_html_edit_props do
    field(:value, non_null(:string))
    field(:original_value, non_null(:string))
  end

  object :change_image_edit_props do
    field(:original_image_url, non_null(:string))
    field(:image_url, non_null(:string))
  end

  input_object :new_change_image_edit do
    field(:original_image_url, non_null(:string))
    field(:image_url, non_null(:string))
  end

  object :link_edit_screen_destination do
    field(:id, non_null(:id))
    field(:screen, non_null(:screen), resolve: dataloader(:screen))
    field(:delay_ms, :integer)
  end

  enum :link_edit_url_destination_target do
    values(Ecto.Enum.values(UrlDestination, :target))
  end

  object :link_edit_url_destination do
    field(:href, non_null(:string))
    field(:target, :link_edit_url_destination_target)
  end

  union :link_edit_destination do
    types([
      :link_edit_screen_destination,
      :link_edit_url_destination
    ])

    resolve_type(fn
      %Edit.Link.ScreenDestination{}, _ -> :link_edit_screen_destination
      %Edit.Link.UrlDestination{}, _ -> :link_edit_url_destination
    end)
  end

  object :link_edit_props do
    field(:target_screen_id, :id, deprecate: "use destination")

    field(:target_screen, :screen,
      deprecate: "use destination",
      resolve: dataloader(:screen)
    )

    field :destination, non_null(:link_edit_destination) do
      resolve(&link_edit_destination/3)
    end
  end

  object :scroll_edit_props do
    field(:top, non_null(:float))
    field(:left, non_null(:float))
  end

  input_object :new_scroll_edit do
    field(:top, non_null(:float))
    field(:left, non_null(:float))
  end

  input_object :new_screen_link_edit do
    field(:id, non_null(:id))
    field(:delay_ms, :integer)
  end

  input_object :new_url_link_edit do
    field(:href, non_null(:string))
    field(:target, :link_edit_url_destination_target)
  end

  input_object :new_link_edit do
    field(:target_screen_id, :id, deprecate: "use toScreen")
    field(:to_screen, :new_screen_link_edit)
    field(:to_url, :new_url_link_edit)
  end

  input_object :new_style_edit_props do
    field(:underline, :boolean)
    field(:bold, :boolean)
    field(:hide, :boolean)
    field(:font_size, :string)
    field(:color, :string)
  end

  union :edit do
    types([
      :text_edit,
      :style_edit,
      :html_edit,
      :change_image_edit,
      :link_edit,
      :scroll_edit,
      :binding_edit
    ])

    resolve_type(fn
      %Edit{kind: :text}, _ -> :text_edit
      %Edit{kind: :style}, _ -> :style_edit
      %Edit{kind: :html}, _ -> :html_edit
      %Edit{kind: :change_image}, _ -> :change_image_edit
      %Edit{kind: :link}, _ -> :link_edit
      %Edit{kind: :scroll}, _ -> :scroll_edit
      %Edit{kind: :binding}, _ -> :binding_edit
    end)
  end

  object :text_edit do
    field(:id, non_null(:id))
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:text_edit_props, non_null(:text_edit_props))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  object :binding_edit do
    field(:id, non_null(:id))
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:binding_edit_props, non_null(:binding_edit_props))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  object :style_edit do
    field(:id, non_null(:id))
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:style_edit_props, non_null(:style_edit_props))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  object :html_edit do
    field(:id, non_null(:id))
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:html_edit_props, non_null(:html_edit_props))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  object :change_image_edit do
    field(:id, non_null(:id))
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:change_image_edit_props, non_null(:change_image_edit_props))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  object :link_edit do
    field(:id, non_null(:id))
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:link_edit_props, non_null(:link_edit_props))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  object :scroll_edit do
    field(:id, non_null(:id))
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:scroll_edit_props, non_null(:scroll_edit_props))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  input_object :new_edit do
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:style_edit_props, :new_style_edit_props)
    field(:text_edit_props, :new_text_edit_props)
    field(:html_edit_props, :new_html_edit_props)
    field(:change_image_edit_props, :new_change_image_edit)
    field(:link_edit_props, :new_link_edit)
    field(:scroll_edit_props, :new_scroll_edit)
    field(:binding_edit_props, :new_binding_edit_props)
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector_input)
  end

  input_object :updated_edit do
    field(:id, non_null(:id))
    field(:kind, non_null(:edit_kind))
    field(:last_edited_at, non_null(:datetime))
    field(:style_edit_props, :new_style_edit_props)
    field(:text_edit_props, :new_text_edit_props)
    field(:html_edit_props, :new_html_edit_props)
    field(:change_image_edit_props, :new_change_image_edit)
    field(:link_edit_props, :new_link_edit)
    field(:scroll_edit_props, :new_scroll_edit)
    field(:binding_edit_props, :new_binding_edit_props)
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector_input)
  end

  input_object :delete_edit do
    field(:id, non_null(:id))
  end

  object :editing_mutations do
    @desc "Adds new edits to a screen"
    field :add_edits_to_screen, non_null(list_of(non_null(:edit))) do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_id, non_null(:id))
      arg(:edits, non_null(list_of(non_null(:new_edit))))

      resolve(fn
        _parent, %{screen_id: screen_id, edits: edits}, %{context: %{current_member: actor}} ->
          edits = GraphQLHelpers.translate_mutation_polymorphism_of_edits(edits)

          with {:ok, edits} <- Storylines.add_edits(screen_id, edits, actor) do
            edits |> Enum.each(&ApiWeb.Analytics.report_edit_created(actor.user, &1))

            list_edits = Editing.list_edits(screen_id)
            {:ok, list_edits}
          end
      end)
    end

    @desc "Updates an existing edit"
    field :update_edits_in_screen, non_null(list_of(non_null(:edit))) do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_id, non_null(:id))
      arg(:edits, non_null(list_of(non_null(:updated_edit))))

      resolve(fn _parent,
                 %{screen_id: screen_id, edits: edits},
                 %{context: %{current_member: actor}} ->
        edits = GraphQLHelpers.translate_mutation_polymorphism_of_edits(edits)

        with {:ok, _res} <- Storylines.update_edits(screen_id, edits, actor) do
          edits = Editing.list_edits(screen_id)
          edits |> Enum.each(&ApiWeb.Analytics.report_edit_updated(actor.user, &1))

          {:ok, edits}
        end
      end)
    end

    @desc "Deletes all provided edits"
    field :delete_edits_in_screen, :boolean do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_id, non_null(:id))
      arg(:edits, non_null(list_of(non_null(:delete_edit))))

      resolve(fn _parent,
                 %{screen_id: screen_id, edits: edits},
                 %{context: %{current_member: actor}} ->
        edits = edits |> Enum.map(fn edit -> %Editing.Edit{id: edit.id} end)

        with {:ok, res} <- Editing.delete_edits(screen_id, edits, actor) do
          res
          |> Enum.map(&elem(&1, 1))
          |> Enum.each(&ApiWeb.Analytics.report_edit_deleted(actor.user, &1))

          {:ok, true}
        end
      end)
    end
  end

  # We use this resolver to support backward compatibility (in the db) of the destination object
  defp link_edit_destination(parent, _, _) do
    data = parent |> Link.destination()
    {:ok, data}
  end

  defp binding_edit_program_resolver(parent, _, _) do
    Jason.encode(parent.program_embed)
  end
end
