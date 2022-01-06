defmodule Api.AssetManifests.AssetManifest do
  @moduledoc """


  NOTE: we are currently not using this modules, but they are the foundation for
  using the asset manifests for useful things!

  Represents an AssetManifest

  An asset manifest holds record of all the assets that are linked to an HTML page.
  It also keeps track of the lifecycle of an asset during the capture process.

  An asset can be at one of these states:
  Detected: The asset was detected during the capture, it wasn't yet downloaded
  DownloadSuccess: We've successfully downloaded the asset
  DownloadError: We've failed to download the asset
  AssetRepoStoreSuccess: We've successfully stored the asset in our asset repository
  AssetRepoStoreError: We've failed to store the asset in our asset repository
  """

  use Api.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "asset_manifests" do
    has_many(:assets, Api.AssetManifests.AssetManifest.Asset)
    timestamps()
  end
end
