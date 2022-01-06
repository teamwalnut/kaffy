defmodule ApiWeb.AssetController do
  require Logger
  use ApiWeb, :controller
  action_fallback(ApiWeb.FallbackController)

  def get(conn, %{"name" => name}) do
    case Api.Assets.stream_by_name(name) do
      {:ok, %Tesla.Env{status: 200} = response} ->
        stream_resp(conn, response)

      {:ok, %Tesla.Env{status: status} = response} ->
        Logger.warn("Not 200 response while fetching assets",
          fetch_asset_name: name,
          fetch_asset_result: inspect(response),
          status: response.status
        )

        conn |> send_resp(status, "")

      {:error, error} ->
        Logger.warn("Error fetching asset",
          fetch_asset_name: name,
          fetch_asset_result: inspect(error)
        )

        conn |> send_resp(500, "Error fetching asset")
    end
  end

  defp stream_resp(conn, response) do
    conn =
      conn
      # note(itay): This header is added by Phoenix for every response, we clean it up here since we don't
      # want it to cause issues for asset fetching inside an iframe
      |> put_resp_header("cache-control", "immutable, max-age=31536000, public")
      |> put_resp_header("access-control-allow-origin", "*")
      |> merge_resp_headers(response.headers)
      |> delete_resp_header("x-frame-options")
      |> send_chunked(200)

    Enum.reduce_while(response.body, conn, fn chunk, conn ->
      send_chunk(conn, chunk)
    end)
  end

  defp send_chunk(conn, nil) do
    Logger.error("Sending an asset with size 0")

    {:halt, conn}
  end

  defp send_chunk(conn, chunk) do
    case Plug.Conn.chunk(conn, chunk) do
      {:ok, conn} ->
        {:cont, conn}

      {:error, :closed} ->
        {:halt, conn}
    end
  end

  def register(conn, %{"name" => name}) do
    case Api.Assets.register(%{"name" => name}) do
      {:ok, _asset} ->
        conn |> put_status(200) |> json(%{ok: "ok"})

      {:error, changeset} ->
        conn
        |> put_status(208)
        |> json(%{"error" => Ecto.Changeset.traverse_errors(changeset, fn {err, _} -> err end)})
    end
  end

  # Same as above, but allows for an array
  def register(conn, %{"names" => names}) do
    result = Api.Assets.register(names)

    if result <= 0 do
      Logger.warn("no assets inserted", %{names: names})
    end

    conn |> put_status(200) |> json(%{ok: "ok"})
  end

  def filter_existing(conn, %{"assets" => uris}) do
    filtered = Api.Assets.filter_existing(uris)

    conn |> put_status(200) |> json(filtered)
  end
end
