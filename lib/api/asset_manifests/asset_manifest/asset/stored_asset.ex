defmodule Api.AssetManifests.AssetManifest.Asset.StoredAsset do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:url, :string)
  end
end
