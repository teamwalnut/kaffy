defmodule Api.Storylines.ScreenGrouping.Flow do
  @moduledoc """
  Responsible for organizing screens inside a storyline.
  A storyline will always have at least 1 flow which will be the "default" flow (marked with the "is_default" attribute),
  and can have an unlimited number of flows.
  A flow has a name, and groups screens togther via the FlowScreen entity.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Api.Storylines.Demos
  alias Api.Storylines.ScreenGrouping.{Flow, FlowScreen}

  @position_index_basis 1

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "flows" do
    field :name, :string
    field :is_default, :boolean
    field :position, :integer
    belongs_to(:storyline, Api.Storylines.Storyline)
    belongs_to(:demo_version, Api.Storylines.Demos.DemoVersion)
    has_many(:flow_screens, FlowScreen)
    has_many(:screens, through: [:flow_screens, :screen], preload_order: [desc: :updated_at])

    timestamps()
  end

  @doc """
  Returns a changeset for creating a default flow.
  It already sets the correct values to the flow's attributes in order
  for it to be consider a "default" flow
  """
  def create_default_flow_changeset(flow) do
    flow
    |> change(name: "Default", is_default: true, position: 1)
    |> unique_constraint([:is_default, :storyline_id, :demo_version_id],
      message: "can only have 1 default Flow per Storyline or DemoVersion"
    )
    |> validate_unique_position()
  end

  @doc """
  Returns a changeset for creating a "regular" flow.
  """
  def create_changeset(flow, attrs) do
    flow
    |> cast(attrs, [:name, :position])
    |> put_change(:is_default, false)
    |> validate_required([:name, :position])
    |> unique_constraint([:is_default, :storyline_id, :demo_version_id],
      message: "can only have 1 default Flow per Storyline or DemoVersion"
    )
    # NOTE(paz): "Regular" flows will always start from 2 and above, as position 1 is reserved for the default flow
    |> validate_position()
    |> validate_unique_position()
  end

  @doc """
  Returns a changeset for renaming a flow.
  """
  def rename_changeset(flow, attrs) do
    flow
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  @doc """
  Returns a changeset for repositioning a flow.
  """
  def reposition_changeset(flow, attrs) do
    flow
    |> cast(attrs, [:position])
    |> validate_position()
    |> unique_constraint([:position, :storyline_id],
      message: "can't have 2 flows in the same position"
    )
  end

  @doc """
  Returns a changeset for deleting a flow.
  """
  def delete_changeset(flow) do
    flow
    |> validate_not_default()
  end

  defp validate_not_default(flow) do
    # note(itay): Since validate_acceptance will pass only if the value is true, I reverse the given value `is_default`
    # since we want to fail in case we are attempting to delete the default flow.
    flow
    |> cast(%{is_default: !flow.is_default}, [:is_default])
    |> validate_acceptance(:is_default, message: "can't delete a default flow")
  end

  defp validate_unique_position(changeset) do
    changeset
    |> unsafe_validate_unique([:position, :storyline_id], Api.Repo,
      message: "can't have 2 flows in the same position"
    )
    |> unique_constraint([:position, :storyline_id],
      message: "can't have 2 flows in the same position"
    )
  end

  defp validate_position(changeset) do
    changeset
    |> validate_number(:position, greater_than_or_equal_to: 2)
  end

  @doc """
  Returns a query that returns all flows for the passed storyline_id
  """
  def list_query(storyline_id) do
    from flow in by_position_query(),
      join: storyline in assoc(flow, :storyline),
      where: storyline.id == ^storyline_id
  end

  @doc """
  Returns a query that returns all flows for the passed demo_id
  """
  def list_demo_query(demo_id) do
    active_demo_version = Demos.get_active_demo_version!(demo_id)

    from flow in by_position_query(),
      join: demo_version in assoc(flow, :demo_version),
      where: demo_version.id == ^active_demo_version.id
  end

  @doc """
  Returns the default flow from a storyline_id
  """
  def default_flow_query(storyline_id) do
    from flow in Flow,
      join: storyline in assoc(flow, :storyline),
      where: storyline.id == ^storyline_id and flow.is_default == true
  end

  @doc """
  Query that returns all flows ordered by position
  """
  def by_position_query do
    from(flow in Flow,
      order_by: [asc: :position]
    )
  end

  def defer_position_unique_constraint_query do
    "SET CONSTRAINTS flows_position_storyline_id DEFERRED"
  end

  def position_index_basis do
    @position_index_basis
  end
end
