defmodule Api.Storylines.Editing.Edit.Scroll do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:top, :left]}
  @primary_key false
  embedded_schema do
    field(:top, :float)
    field(:left, :float)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:top, :left])
    |> validate_required([:top, :left])
  end
end
