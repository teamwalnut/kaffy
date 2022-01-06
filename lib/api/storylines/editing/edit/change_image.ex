defmodule Api.Storylines.Editing.Edit.ChangeImage do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:original_image_url, :image_url]}
  @primary_key false
  embedded_schema do
    field(:original_image_url, :string, default: "")
    field(:image_url, :string)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:original_image_url, :image_url])
    |> validate_required([:image_url])
  end
end
