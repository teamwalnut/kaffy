defmodule Api.Storylines.Editing.Edit.Link.UrlDestination do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive {Jason.Encoder, only: [:href, :target, :kind]}
  embedded_schema do
    field :kind, :string, default: "url"
    field :href, :string
    field(:target, Ecto.Enum, values: [:new_tab, :same_tab], default: :new_tab)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:href, :target])
    |> validate_required([:href])
  end
end
