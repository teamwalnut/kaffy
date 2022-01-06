defmodule Api.AssetManifests.AssetManifest.Asset.DetectedAsset.FrameDetectedAsset do
  @moduledoc false
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:frame_id, :string)
    field(:parent_frame_id, :string)
  end
end
