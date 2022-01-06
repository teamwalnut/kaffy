defmodule Api.Storylines.Editing.Edit.Html do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:original_value, :value, :position]}
  @primary_key false
  embedded_schema do
    field(:original_value, :string, default: "")
    field(:value, :string)
    field(:position, Ecto.Enum, values: [:before, :after, :replace], default: :replace)
  end

  defp validate_non_null(changeset) do
    if get_field(changeset, :value) == nil do
      add_error(changeset, :value, "can't be nil")
    else
      changeset
    end
  end

  def changeset(schema, attrs) do
    schema
    # by default "" is an "empty value" in ecto changesets
    # in this case we want to allow "" because nil is not allowed
    # edit can set the string to "", so we want to allow it
    |> cast(attrs, [:original_value, :value, :position], empty_values: [])
    |> validate_non_null()
  end
end
