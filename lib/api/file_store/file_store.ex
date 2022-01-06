defmodule Api.FileStore do
  @moduledoc """
  This module provides a simple file storage behavior, which serves as an general interface on
  top of S3. `Api.FileStore.S3` and `Api.FileStore.Mock` are implementations of this.
  """
  @callback upload_asset(path :: String.t(), contents :: binary(), content_type :: String.t()) ::
              :ok | {:error, :upload_failed}

  @callback upload_artifact(
              path :: String.t(),
              contents :: binary(),
              content_type :: String.t()
            ) ::
              :ok | {:error, :upload_failed}
end
