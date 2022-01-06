defmodule Api.Storylines.Editing.Edit do
  @moduledoc """
  Represent a single edit, we've different Kinds of edits, defined by the :kind enum.
  Each edit has associated embed to it that stores the edit properties
  """
  use Api.Schema

  alias __MODULE__

  alias __MODULE__.{
    Binding,
    ChangeImage,
    Html,
    Scroll,
    Style,
    Text,
    Link
  }

  import Link.ScreenDestination.Fragments
  import Binding.Fragments

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder,
           only: [
             :screen_id,
             :last_edited_at,
             :kind,
             :css_selector,
             :frame_selectors,
             :dom_selector,
             :change_image_edit_props,
             :html_edit_props,
             :link_edit_props,
             :scroll_edit_props,
             :style_edit_props,
             :text_edit_props,
             :binding_edit_props
           ]}
  schema "edits" do
    field(:css_selector, :string)
    field(:frame_selectors, {:array, :string})

    embeds_one(:dom_selector, Api.DOMSelector, on_replace: :update)

    field(:kind, Ecto.Enum,
      values: [:style, :text, :link, :change_image, :scroll, :html, :binding]
    )

    field(:last_edited_at, :utc_datetime_usec)

    embeds_one(:change_image_edit_props, ChangeImage, on_replace: :update)
    embeds_one(:html_edit_props, Html, on_replace: :update)
    embeds_one(:link_edit_props, Link, on_replace: :update)
    embeds_one(:scroll_edit_props, Scroll, on_replace: :update)
    embeds_one(:style_edit_props, Style, on_replace: :update)
    embeds_one(:text_edit_props, Text, on_replace: :update)
    embeds_one(:binding_edit_props, Binding, on_replace: :update)

    belongs_to(:screen, Api.Storylines.Screen)

    timestamps()
  end

  def to_map(%__MODULE__{} = e) do
    e
    |> Map.from_struct()
    |> Map.take(__schema__(:fields))
  end

  @spec to_attributes(any() | [any()]) :: map() | [map()] | no_return()
  def to_attributes(value) do
    value
    |> Jason.encode!()
    |> Jason.decode!()
  end

  @doc false
  def create_changeset(screen_id, kind, attrs) do
    screen_id |> create_edit_with_type(kind, attrs)
  end

  @doc false
  def update_changeset(%Edit{} = edit, attrs) do
    edit |> update_edit_with_type(attrs)
  end

  defp create_edit_with_type(screen_id, kind, attrs) do
    prop_atom = kind |> prop_atom_from_kind()
    module = kind_to_module(kind)

    %Edit{screen_id: screen_id, kind: kind}
    |> cast(attrs, [:frame_selectors, :css_selector, :last_edited_at])
    |> cast_embed(:dom_selector)
    |> cast_embed(prop_atom, with: &module.changeset/2, required: true)
    |> validate_required([prop_atom, :css_selector, :last_edited_at])
  end

  defp update_edit_with_type(%Edit{kind: kind} = edit, attrs) do
    prop_atom = kind |> prop_atom_from_kind()
    module = kind_to_module(kind)

    edit
    |> cast(attrs, [:frame_selectors, :css_selector, :last_edited_at])
    |> cast_embed(:dom_selector)
    |> cast_embed(prop_atom, with: &module.changeset/2, required: true, on_replace: :update)
    |> validate_required([:id, prop_atom, :css_selector, :last_edited_at])
  end

  def link_to_screen?(%Edit{
        kind: :link,
        link_edit_props: %Edit.Link{destination: %Link.ScreenDestination{}}
      }),
      do: true

  def link_to_screen?(%Edit{
        kind: :link,
        link_edit_props: %Edit.Link{target_screen_id: _}
      }),
      do: true

  def link_to_screen?(%Edit{kind: _}), do: false

  def link_to_screen?(_), do: false

  @doc """
  Takes a list of screen ids and checks if a link edit links to one of them
  """
  def linked_to_screen_ids?(
        %Edit{
          kind: :link,
          link_edit_props: %Edit.Link{destination: %Link.ScreenDestination{} = destination}
        } = edit,
        screen_ids
      ) do
    case link_to_screen?(edit) do
      true ->
        destination_screen_id =
          destination
          |> Edit.Link.ScreenDestination.id()

        destination_screen_id in screen_ids

      false ->
        false
    end
  end

  def linked_to_screen_ids?(_, _), do: false

  def props(%Edit{kind: kind} = edit) do
    Map.get(edit, prop_atom_from_kind(kind))
  end

  defp prop_atom_from_kind(kind) do
    kind_string = Atom.to_string(kind)
    "#{kind_string}_edit_props" |> String.to_atom()
  end

  def bindings_variables_by_storyline_id_query(storyline_id) do
    from(edit in __MODULE__,
      join: screen in assoc(edit, :screen),
      join: storyline in assoc(screen, :storyline),
      where:
        storyline.id == ^storyline_id and
          edit.kind == :binding and
          program_embed_fn_name(edit.binding_edit_props) == ^"PUBLIC_FIELD"
    )
  end

  def by_screen_id_query(screen_id) do
    from(edits in __MODULE__,
      where: edits.screen_id == ^screen_id,
      order_by: [asc: edits.updated_at]
    )
  end

  def by_screen_id_and_kind_query(screen_id, kind) do
    from(edits in __MODULE__,
      where: edits.screen_id == ^screen_id and edits.kind == ^kind
    )
  end

  def links_to_screen_query(screen_id) do
    from(edits in __MODULE__,
      where: edits.kind == :link,
      where: target_screen_id(edits.link_edit_props) == ^screen_id
    )
  end

  defp kind_to_module(kind) do
    kind = kind |> Atom.to_string() |> Macro.camelize()
    "Elixir.Api.Storylines.Editing.Edit.#{kind}" |> String.to_existing_atom()
  end

  def link_edits_between_screens(storyline_screen_ids) do
    from(edit in __MODULE__,
      where: edit.screen_id in ^storyline_screen_ids,
      where: target_screen_id(edit.link_edit_props) in ^storyline_screen_ids
    )
  end

  # NOTE(@diogo): These edits usually are a map instead of a %__MODULE__{}
  # since they're coming from SmartObjects.Class or SmartObjects.Instance
  def validate_many(edits) do
    edits
    |> Enum.all?(fn edit ->
      selector =
        Map.get(edit, :css_selector) ||
          Map.get(edit, "css_selector") ||
          ""

      selector
      |> String.trim()
      |> String.length() >
        0
    end)
  end
end
