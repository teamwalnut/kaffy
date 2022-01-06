defmodule Api.AssetManifests.AssetManifest.Asset do
  @moduledoc """
  Represents an Asset thats part of an AssetManifest
  For more details about AssetManifest check Api.AssetManifests.AssetManifest
  """
  use Api.Schema

  schema "asset_manifests_asset" do
    field(:asset_id, :string)
    field(:asset_contents_hash, :string)
    belongs_to(:asset_manifest, Api.AssetManifests.AssetManifest)
    embeds_one(:detected_asset, DetectedAsset, on_replace: :update)
    embeds_one(:downloaded_asset, DownloadedAsset, on_replace: :update)
    embeds_one(:stored_asset, StoredAsset, on_replace: :update)
    timestamps()
  end
end
