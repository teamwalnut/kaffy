defmodule Api.Storylines.Screen.Dimensions do
  @moduledoc false
  use Api.Schema

  @derive {Jason.Encoder,
           except: [
             :__struct__
           ]}
  @primary_key false
  embedded_schema do
    field(:width, :integer)
    field(:height, :integer)
    field(:doc_height, :integer)
    field(:doc_width, :integer)
  end

  def changeset(dimensions, attrs) do
    dimensions
    |> cast(attrs, [
      :width,
      :height,
      :doc_height,
      :doc_width
    ])
    |> validate_required([
      :width,
      :height
    ])
  end
end
