defmodule Api.Storylines.Editing.Edit.Link.ScreenDestination do
  @moduledoc false

  defmodule Fragments do
    @moduledoc false
    defmacro target_screen_id(props) do
      quote do
        fragment(
          "? -> 'destination' ->> 'id'",
          unquote(props)
        )
      end
    end
  end

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive {Jason.Encoder, only: [:id, :kind, :delay_ms]}
  embedded_schema do
    field :id, :string
    field :kind, :string, default: "screen"
    field :delay_ms, :integer

    belongs_to :screen, Api.Storylines.Screen,
      foreign_key: :id,
      references: :id,
      define_field: false
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:id, :delay_ms])
    |> validate_required([:id])
  end

  def id(dest) do
    if dest.kind == "screen", do: dest.id, else: nil
  end

  def load(data) when is_map(data) do
    {:ok, struct!(ScreenDestination, data)}
  end
end
