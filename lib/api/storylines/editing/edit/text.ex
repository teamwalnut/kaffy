defmodule Api.Storylines.Editing.Edit.Text do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:original_text, :text]}
  @primary_key false
  embedded_schema do
    field(:original_text, :string, default: "")
    field(:text, :string)
  end

  defp validate_non_null(changeset) do
    if get_field(changeset, :text) == nil do
      add_error(changeset, :text, "can't be nil")
    else
      changeset
    end
  end

  def changeset(schema, attrs) do
    schema
    # by default "" is an "empty value" in ecto changesets
    # in this case we want to allow "" because nil is not allowed
    # edit can set the string to "", so we want to allow it
    |> cast(attrs, [:original_text, :text], empty_values: [])
    |> validate_non_null()
  end
end
