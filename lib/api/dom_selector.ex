defmodule Api.DOMSelector do
  @moduledoc """

  In order to support dealing with multiple representations of selectors for
  DOM elements, we introduce the DOMSelector embedded schema.

  This _doesn't have to be_ an `embedded_schema` but it helps when including it
  in other Ecto schemas.

  The main positive out of this, instead of using several `:string` fields, is
  that we can use this module to put functions (changeset validation, etc) that
  help maintain invariants.

  For example, a DOMSelector can be in XPath or in CSS format, but they both
  need to be equivalent. If they aren't, then validation shouldn't pass. This
  is to make sure we don't enter any illegal states (such as an XPath pointing
  to a different element than the CSS counterpart).

  """
  use Api.Schema

  @derive {Jason.Encoder,
           except: [
             :__struct__
           ]}

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field(:xpath_node, :string)
    field(:xpath_frames, {:array, :string}, default: [])
  end

  @doc """
  Creates a new Changeset for a DOMSelector struct from an XPath string.
  """
  def from_xpath(xpath_node, xpath_frames) when is_binary(xpath_node) do
    changeset(
      %__MODULE__{},
      %{xpath_node: xpath_node, xpath_frames: xpath_frames}
    )
  end

  def changeset(%__MODULE__{} = schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [:xpath_node, :xpath_frames])
    # # NOTE(@ostera): at this point we can use an external library to validate
    # # that the XPath is in the right format
    |> validate_required([:xpath_node, :xpath_frames])
  end

  def to_attributes(value) do
    value |> Jason.encode!() |> Jason.decode!()
  end
end
