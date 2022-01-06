defmodule Api.Storylines.ScreenGrouping.FlowScreen do
  @moduledoc """
  Responsible for connecting between a screen and a flow while also defining the position of that screen in the flow.
  """
  use Api.Schema

  alias Api.Storylines.ScreenGrouping.{Flow, FlowScreen}

  @position_index_basis 1

  schema "flow_screens" do
    field :position, :integer
    belongs_to(:screen, Api.Storylines.Screen)
    belongs_to(:flow, Flow)

    timestamps()
  end

  @doc false
  def create_changeset(flow_screen, attrs) do
    flow_screen
    |> cast(attrs, [:position])
    |> validate_required([:position, :screen_id, :flow_id])
    |> validate_number(:position, greater_than_or_equal_to: 1)
    |> unsafe_validate_unique([:position, :flow_id], Api.Repo,
      message: "can't have 2 screens in the same position"
    )
    |> unique_constraint([:position, :flow_id],
      message: "can't have 2 screens in the same position"
    )
    |> unsafe_validate_unique(:screen_id, Api.Repo,
      message: "Screen can't exist in more than 1 Flow"
    )
    |> unique_constraint(:screen_id, message: "Screen can't exist in more than 1 Flow")
  end

  @doc """
  Returns a changeset for repositioning a flow_screen.
  """
  def reposition_changeset(flow_screen, attrs) do
    flow_screen
    |> cast(attrs, [:position, :flow_id])
    |> validate_required(:position)
    |> validate_number(:position, greater_than_or_equal_to: 1)
    |> unique_constraint([:position, :flow_id],
      message: "can't have 2 screens in the same position"
    )
  end

  @doc """
  Returns a query that orders flow_screens by their posistion ASC
  """
  def order_by_position_query do
    from(flow_screen in FlowScreen, order_by: [asc: :position])
  end

  @doc """
  Returns a query that returns the biggest flow_screens.position for the given flow_id
  """
  def max_position_query(flow_id) do
    from(flow_screen in FlowScreen,
      join: flow in assoc(flow_screen, :flow),
      where: flow.id == ^flow_id,
      select: max(flow_screen.position)
    )
  end

  @doc false
  def count_by_demo_versions_query(query, demo_version_ids) do
    query
    |> join(:inner, [fs], f in Flow, on: fs.flow_id == f.id)
    |> exclude(:order_by)
    |> where([_, f], f.demo_version_id in ^demo_version_ids)
    |> group_by([_, f], f.demo_version_id)
    |> select([_, f], {f.demo_version_id, count("*")})
  end

  def defer_position_unique_constraint_query do
    "SET CONSTRAINTS flow_screens_position_flow_id DEFERRED"
  end

  def position_index_basis do
    @position_index_basis
  end
end
