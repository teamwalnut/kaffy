defmodule Api.FileStore.S3 do
  @behaviour Api.FileStore
  @moduledoc """
  S3 FileStore implementation.
  """

  @impl Api.FileStore
  def upload_asset(path, contents, content_type) do
    ExAws.S3.put_object(bucket_name(), path, contents, [
      {:content_type, content_type},
      {:cache_control, "max-age=31536000,immutable,public"}
    ])
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :upload_failed}
    end
  end

  @impl Api.FileStore
  def upload_artifact(path, contents, content_type) do
    ExAws.S3.put_object(artifact_bucket_name(), path, contents, [
      {:content_type, content_type}
    ])
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :upload_failed}
    end
  end

  defp bucket_name do
    Application.get_env(:api, :s3)[:bucket_name]
  end

  defp env do
    System.get_env("ENVIRONMENT")
  end

  defp artifact_bucket_name do
    Application.get_env(:api, :s3)[:artifact_bucket_name] <> env()
  end
end
