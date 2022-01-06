defmodule Api.S3.TeslaMint do
  @moduledoc """
  Tesla HTTPClient thats used for streaming S3 objects
  """
  use Tesla

  adapter(Tesla.Adapter.Mint, body_as: :stream, mode: :passive)
end
