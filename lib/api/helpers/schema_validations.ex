defmodule Api.SchemaValidations do
  @moduledoc """
  This module is a helper module that stores common validation functions or values needed for format validations.
  It is imported on Api.Schema and on Api.EmbededSchema
  """

  import Ecto.Changeset

  @hex_format_regex ~r/^#([A-Fa-f0-9]{3,4}){1,2}$/i

  def hex_format_regex do
    @hex_format_regex
  end

  @doc """
  Similar to validate_required but checks that *at least one of* fields exists
  """
  def validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      add_error(changeset, hd(fields), "One of these fields must be present: #{inspect(fields)}")
    end
  end

  defp present?(changeset, field) do
    value = get_field(changeset, field)
    value && value != ""
  end
end
