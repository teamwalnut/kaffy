defmodule Api.Storylines.Demos.DemoVersion do
  @moduledoc """
  Represents a demo version,
  an instance of storyline, wrapped with demo,
  which is reffered in guides, flows, etc.
  """
  use Api.Schema
  import Ecto.Changeset

  schema "demo_versions" do
    belongs_to(:start_screen, Api.Storylines.Screen)
    belongs_to(:demo, Api.Storylines.Demos.Demo)
    belongs_to(:created_by, Api.Companies.Member)
    has_many(:flows, Api.Storylines.ScreenGrouping.Flow)

    has_many(:screens,
      through: [:flows, :flow_screens, :screen]
    )

    has_many(:patches, Api.Patching.Patch)
    has_one(:default_flow, Api.Storylines.ScreenGrouping.Flow, where: [is_default: true])
    has_many(:guides, Api.Annotations.Guide)
    has_one(:settings, Api.Settings.DemoVersionSettings)
    has_one(:company, through: [:demo, :storyline, :company])
    timestamps()
  end

  @doc false
  def changeset(demo, attrs) do
    demo
    |> cast(attrs, [])
    |> validate_required([:start_screen_id])
    |> foreign_key_constraint(:created_by_id)
  end

  @doc """
  Updates start screen of demo_version, it's used to set thumbnail of demo
  """
  def update_start_screen(demo_version, attrs) do
    demo_version
    |> cast(attrs, [:start_screen_id])
    |> foreign_key_constraint(:start_screen_id)
  end

  @doc """
  Updates demo_id
  """
  def update_demo_id_changeset(demo_version, attrs) do
    demo_version
    |> cast(attrs, [:demo_id])
    |> validate_required([:demo_id])
    |> foreign_key_constraint(:demo_id)
  end
end
