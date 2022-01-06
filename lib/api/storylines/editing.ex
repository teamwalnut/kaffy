defmodule Api.Storylines.Editing do
  @moduledoc """
  The Editing context.
  """

  import Ecto.Query, warn: false
  alias Api.Repo
  alias Api.Storylines.Editing.Edit
  alias Api.Storylines.Screen
  alias Api.Storylines.Storyline
  alias Ecto.Multi
  require Logger

  @doc """
  Returns the list of edits.

  ## Examples

      iex> list_edits(screen_id)
      [%Edit{}, ...]

  """
  def list_edits(screen_id) do
    Edit.by_screen_id_query(screen_id) |> Repo.all()
  end

  @doc """
  Returns the list of edits by specific kind.

  ## Examples

      iex> list_edits_screen_by_kind(screen_id, kind)
      [%Edit{}, ...]

  """
  def list_edits_screen_by_kind(screen_id, kind) do
    Edit.by_screen_id_and_kind_query(screen_id, kind) |> Repo.all()
  end

  @doc """
  Returns a list of all links pointing to the screen

  ## Examples

      iex> delete_links_to_screen(screen_id)
      [%Edit.Link{}, ...]

  """
  def delete_links_to_screen(screen_id) do
    Edit.links_to_screen_query(screen_id) |> Repo.delete_all()
  end

  @doc """
  Adds multiple edits one by one, returns :ok if all succeeded, and %{errors: [error_changset]} if any failed,
  each edit must have a :kind to determine its type.
  """
  def add_edits(screen_id, edits) do
    Repo.transaction(fn ->
      screen = Screen |> Repo.get!(screen_id) |> Repo.preload(storyline: [])

      screen.storyline
      |> Storyline.last_edited_changeset(%{last_edited: DateTime.utc_now()})
      |> Repo.update!()

      edits
      |> Enum.reduce([], fn edit, acc ->
        # credo:disable-for-next-line Credo.Check.Refactor.Nesting
        case add_edit(screen_id, edit) do
          {:ok, edit} ->
            edit = edit |> Repo.preload(:screen)

            Enum.concat(acc, [edit])

          {:error, err} ->
            Logger.error("Error inserting edit", %{error: err})
            acc
        end
      end)
    end)
  end

  def add_edit(
        screen_id,
        %{
          kind: kind,
          css_selector: css_selector,
          last_edited_at: last_edited_at,
          dom_selector: dom_selector
        } = props
      ) do
    frame_selectors = props |> Map.get(:frame_selectors)
    edit_specific_prop_key = String.to_existing_atom("#{kind}_edit_props")
    edit_specific_attrs = props |> Map.get(edit_specific_prop_key)

    changeset_props =
      %{
        kind: kind,
        css_selector: css_selector,
        frame_selectors: frame_selectors,
        last_edited_at: last_edited_at,
        dom_selector: dom_selector
      }
      |> Map.put_new(edit_specific_prop_key, edit_specific_attrs)

    screen_id
    |> Edit.create_changeset(kind, changeset_props)
    |> Repo.insert()
  end

  def add_edit(
        screen_id,
        %{
          kind: _kind,
          css_selector: _css_selector,
          last_edited_at: _last_edited_at
        } = props
      ),
      do: add_edit(screen_id, props |> Map.put(:dom_selector, nil))

  @doc """
  Updates an existing style edit with a new style attributes
  Updates multiple existing edits in a transaction,
  each edit must have a :kind to determine its type.any()
  """
  def update_edits(_screen_id, edits) do
    edits
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {edit, index}, multi ->
      edit =
        case edit |> Map.has_key?(:dom_selector) && edit.dom_selector != nil do
          true ->
            %{edit | dom_selector: edit.dom_selector |> Api.DOMSelector.to_attributes()}

          false ->
            edit
        end

      changeset =
        Edit.update_changeset(
          %Edit{id: edit.id, kind: edit.kind},
          edit
        )

      Multi.update(multi, {:edit, index}, changeset)
    end)
    |> Repo.transaction()
  end

  @doc """
  Copies all edits from `from_screen_id` to `target_screen_id`
  """
  def copy_edits(from_screen_id, target_screen_id) do
    edits = Edit.by_screen_id_query(from_screen_id) |> Repo.all()

    new_edits =
      edits
      |> Enum.map(fn edit ->
        edit
        |> Edit.to_map()
        |> Map.put(:screen_id, target_screen_id)
        |> Map.delete(:id)
      end)

    {_, new_edits} = Repo.insert_all(Edit, new_edits, returning: true)
    {:ok, new_edits}
  end

  @doc """
  Deletes multiple edits in a transaction

  ## Examples

      iex> delete_edits([edit1, edit2])
      {:ok, %Edit{}}

      iex> delete_edits([edit3])
      {:error, %Ecto.Changeset{}}
  """
  def delete_edits(screen_id, edits, actor) when is_list(edits) do
    screen = Screen |> Repo.get!(screen_id) |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(screen.storyline, actor, :presenter) do
      edits
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {edit, index}, multi ->
        Multi.delete(multi, {:edit, index}, edit)
      end)
      |> Repo.transaction()
    end
  end
end
