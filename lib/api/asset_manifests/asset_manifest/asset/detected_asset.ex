defmodule Api.AssetManifests.AssetManifest.Asset.DetectedAsset do
  @moduledoc false
  use Ecto.Schema

  alias __MODULE__.FrameDetectedAsset
  alias __MODULE__.UrlDetectedAsset

  @primary_key false
  embedded_schema do
    embeds_one(:url_detected_asset, UrlDetectedAsset, on_replace: :update)
    embeds_one(:frame_detected_asset, FrameDetectedAsset, on_replace: :update)
  end
end
