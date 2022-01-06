defmodule Api.Storylines.DemoFlags do
  @moduledoc """
  Various storyline flags controlling how we render the demo/editor
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :adjust_to_origin_dimensions, :boolean, default: false
  end

  def changeset(demo_flags, attrs) do
    demo_flags
    |> cast(attrs, [
      :adjust_to_origin_dimensions
    ])
  end
end
