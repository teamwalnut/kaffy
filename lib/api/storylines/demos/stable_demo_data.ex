defmodule Api.Storylines.Demos.StableDemoData do
  require Logger

  @moduledoc """
  Stable demo data persistance handler, stores static demo data in S3.
  """

  defstruct [
    :demo_id,
    :demo_version_id,
    :demo_hash,
    :demo_data
  ]

  def upload_to_s3(
        %__MODULE__{} = %{
          demo_id: demo_id,
          demo_version_id: demo_version_id,
          demo_hash: demo_hash,
          demo_data: demo_data
        }
      ) do
    if Application.get_env(:api, :env) == "prod" do
      file_store().upload_asset(
        "/demos/#{demo_id}/#{demo_version_id}/#{demo_hash}.json",
        Jason.encode!(demo_data),
        "application/json"
      )
    else
      :ok
    end
  end

  def update_latest_demo_version(demo_id, demo_version_id) do
    if Application.get_env(:api, :env) == "prod" do
      Logger.warn("Updating latest demo version to bucket #{artifact_bucket_name()}")

      file_store().upload_artifact(
        "/demo/latest_versions/#{demo_id}",
        demo_version_id,
        "text/plain"
      )
    else
      :ok
    end
  end

  defp file_store do
    Application.get_env(:api, :file_store)
  end

  defp latest_demo_deploy_commit_sha do
    ExAws.S3.get_object(artifact_bucket_name(), "/demo/LATEST_SHA")
    |> ExAws.request()
    |> case do
      {:ok, file} ->
        Logger.info("Latest commit sha: #{file.body}")
        {:ok, file.body}

      {:error, error} ->
        Logger.error("Can't fetch latest commit sha")
        Logger.error(inspect(error))
        {:error, :error_fetching_latest_version}
    end
  end

  @doc """
  This function copies the index.html of the latest deployed version and saves it in the assets
  bucket saved specifically for this particular demo version.

  The infrastructure lambda function will serve this particular version when this demo version is
  played.

  The index.html links to a fixed version of the Demo Engine assets (it links to assets with a
  commit hash in the path). This makes sure that new changes to the engine can never break existing
  demos.

  To get the latest demo engine a new demo version needs to be created, this will get a fresh
  index.html
  """
  def copy_index_html(demo_version_id) do
    if Application.get_env(:api, :env) == "prod" do
      Logger.info("Copying index.html")
      target_file_name = "/demo/demo_version_htmls/#{demo_version_id}.html"

      case ExAws.S3.head_object(artifact_bucket_name(), target_file_name) |> ExAws.request() do
        {:ok, %{status_code: 200}} ->
          Logger.info("index.html of #{demo_version_id} already copied...")
          :ok

        _ ->
          do_copy_index_html(target_file_name)
      end
    else
      :ok
    end
  end

  defp do_copy_index_html(target_file_name) do
    with {:ok, latest_demo_deploy_commit_sha} <- latest_demo_deploy_commit_sha() do
      ExAws.S3.put_object_copy(
        artifact_bucket_name(),
        target_file_name,
        artifact_bucket_name(),
        "/demo/#{latest_demo_deploy_commit_sha}/index.html"
      )
      |> ExAws.request()
      |> case do
        {:ok, _} ->
          :ok

        {:error, _} ->
          Logger.error("Error copying index.html to: #{target_file_name}...")
          {:error, :copy_index_html_fail}
      end
    end
  end

  defp env do
    System.get_env("ENVIRONMENT")
  end

  defp artifact_bucket_name do
    Application.get_env(:api, :s3)[:artifact_bucket_name] <> env()
  end
end
