defmodule Api.Storylines.Editing.Edit.Style do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:underline, :bold, :hide, :font_size, :color]}
  @primary_key false
  embedded_schema do
    field(:underline, :boolean)
    field(:bold, :boolean)
    field(:hide, :boolean)
    field(:font_size, :string)
    field(:color, :string)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:underline, :bold, :font_size, :color, :hide])
  end
end
