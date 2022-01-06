defmodule Api.Assets do
  @moduledoc """
  Simple asset management service, used to correctly fetch Screen assets
  """
  alias Api.Assets.Asset
  alias Api.Repo
  alias Api.S3.TeslaMint
  require Logger

  @doc """
  Streams an asset from S3
  """
  def stream_by_name(name) do
    {:ok, uri} = s3_api().gen_signed_url(name, :get)
    TeslaMint.get(uri)
  end

  @doc """
  Registers asset in our db for tracking, this is done after an asset was uploaded to storage
  """
  def register(attrs) when is_map(attrs) do
    Asset.create_changeset(%Asset{}, attrs)
    |> Repo.insert()
  end

  def register(names) when is_list(names) do
    timestamp = DateTime.utc_now()

    # Note(Danni): I'm skipping the changeset here to make the fastest inserts possible.
    assets =
      names
      |> Enum.map(&%{name: &1, inserted_at: timestamp, updated_at: timestamp})

    Repo.insert_all(Asset, assets, on_conflict: :nothing)
  end

  @doc """
  Accepts a map of %{"uri" => hash} and filters out all existing assets
  """
  def filter_existing(uris) when is_list(uris) do
    uris =
      uris
      |> Enum.map(&URI.parse/1)
      |> Enum.map(&Map.put(&1, :fragment, nil))
      |> Enum.map(&URI.to_string/1)

    existing =
      uris
      |> Asset.by_uris_query()
      |> Repo.all()
      |> Enum.reduce([], fn asset, acc -> acc ++ [asset.name] end)

    uris
    |> Enum.reject(fn name ->
      Enum.member?(existing, name)
    end)
  end

  defp s3_api do
    Application.get_env(:api, :s3_api)
  end
end
