defmodule Api.AssetManifests.AssetManifest.Asset.DetectedAsset.UrlDetectedAsset do
  @moduledoc false
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:original_url, :string)
    field(:parent_original_url, :string)
  end
end
