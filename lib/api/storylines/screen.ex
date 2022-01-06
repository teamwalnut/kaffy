defmodule Api.Storylines.Screen do
  @moduledoc """
  A screen is a snapshot of DOM stored in S3 coupled with a screenshot and other metadata fields that describe screen.
  """
  use Api.Schema

  alias Api.Storylines.Screen.Dimensions
  alias Api.Storylines.SmartObjects

  schema "screens" do
    field(:screenshot_image_uri, :string)
    field(:last_edited, :utc_datetime_usec)
    field(:name, :string)
    field(:url, :string)
    field(:s3_object_name, :string)
    field(:asset_manifest, :map, default: %{})

    embeds_one(:original_dimensions, Dimensions)
    @doc "A list of other dimensions that were used to capture this screen"
    embeds_many(:available_dimensions, Dimensions)
    embeds_many(:smart_object_instances, SmartObjects.Instance, on_replace: :delete)

    belongs_to(:storyline, Api.Storylines.Storyline)
    has_one(:flow_screen, Api.Storylines.ScreenGrouping.FlowScreen)
    has_one(:flow, through: [:flow_screen, :flow])
    has_many(:edits, Api.Storylines.Editing.Edit)
    has_many(:annotations, Api.Annotations.Annotation)
    has_many(:guides, through: [:annotations, :guide])

    timestamps()
  end

  @doc false
  def create_changeset(screen, attrs) do
    screen
    |> cast(attrs, [
      :name,
      :url,
      :screenshot_image_uri,
      :s3_object_name,
      :asset_manifest
    ])
    |> cast_embed(:original_dimensions)
    |> cast_embed(:available_dimensions)
    |> put_embed(:smart_object_instances, [])
    |> cast_embed(:smart_object_instances)
    |> update_last_edited
    |> validate_required([
      :last_edited,
      :name,
      :url,
      :screenshot_image_uri,
      :s3_object_name
    ])
  end

  @doc false
  def copy_changeset(screen, attrs) do
    screen
    |> cast(attrs, [
      :name,
      :url,
      :last_edited,
      :screenshot_image_uri,
      :s3_object_name,
      :asset_manifest
    ])
    |> cast_embed(:original_dimensions)
    |> cast_embed(:available_dimensions)
    |> cast_embed(:smart_object_instances)
    |> validate_required([
      :name,
      :url,
      :last_edited,
      :screenshot_image_uri,
      :s3_object_name
    ])
  end

  @doc false
  def update_changeset(screen, attrs) do
    screen
    |> cast(attrs, [:name, :url])
    |> cast_embed(:smart_object_instances)
    |> update_last_edited
    |> validate_required([:name, :url])
  end

  @doc false
  def delete_changeset(screen) do
    screen |> change
  end

  @doc false
  def count_by_storylines_query(query, storylines_ids) do
    query
    |> exclude(:order_by)
    |> where([screen], screen.storyline_id in ^storylines_ids)
    |> group_by([screen], screen.storyline_id)
    |> select([screen], {screen.storyline_id, count("*")})
  end

  @doc false
  def all_query do
    # Note(Danni): We're ordering first by updated_at and then by last_edited since
    # when copying, we keep the last_edited the same as the original screen.
    # But we update updated_at/inserted_at. So, when copying a screen,
    # we'll first show the old screens, after them the copied once, and within that
    # we'll order by last_edited.
    # We should just introduce position to avoid this mayhem.
    from(screen in __MODULE__, order_by: [asc: screen.updated_at, desc: screen.last_edited])
  end

  @doc false
  def all_query(screen_ids) do
    all_query() |> where([s], s.id in ^screen_ids)
  end

  @doc """

  Find a screen by its storyline id.

  This function is relying on a field that is deprecated (`storyline_id`).

  """
  def by_storyline_id_query(storyline_id) do
    from(screen in __MODULE__,
      where: screen.storyline_id == ^storyline_id
    )
  end

  def all_with_instances_query(storyline_id) do
    from(screen in __MODULE__,
      where:
        screen.storyline_id == ^storyline_id and not is_nil(screen.smart_object_instances) and
          fragment("jsonb_array_length(?)", screen.smart_object_instances) > 0
    )
  end

  defp update_last_edited(changeset) do
    if changeset.changes != %{} do
      changeset |> put_change(:last_edited, DateTime.utc_now())
    else
      changeset
    end
  end

  def storyline_screen_ids(storyline_id) do
    __MODULE__
    |> where(storyline_id: ^storyline_id)
    |> select([s], s.id)
  end
end
