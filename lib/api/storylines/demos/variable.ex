defmodule Api.Storylines.Demos.Variable do
  @moduledoc """
  Keeps track of what Variables were created in
  a Storyline. Variables are used to modify content in Demos,
  their values are provided during Demo creation.

  A Variable is the definition, and a BindingEdit is the
  implementation of the Variable in the Editor/Demo
  """
  use Api.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "variables" do
    field(:name, :string)
    field(:description, :string)
    field(:kind, Ecto.Enum, values: [:text, :image])
    # note(itay): For simplicity, storing default_value as string instead of creating a sub type
    # for each future value, so far for text/image this should work fine.
    field(:default_value, :string)
    belongs_to(:storyline, Api.Storylines.Storyline)
    timestamps()
  end

  @doc false
  def changeset(demo_token, attrs) do
    demo_token
    |> cast(attrs, [:name, :description, :default_value, :kind])
    |> validate_required([:name, :description, :default_value, :kind])
    |> unique_constraint(:name)
    |> foreign_key_constraint(:storyline_id)
  end
end
