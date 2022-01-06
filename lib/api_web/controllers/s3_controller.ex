defmodule ApiWeb.S3Controller do
  use ApiWeb, :controller

  action_fallback(ApiWeb.FallbackController)

  defmodule S3Api do
    @type presigned_url_opts :: [
            {:expires_in, integer}
            | {:virtual_host, boolean}
            | {:s3_accelerate, boolean}
            | {:query_params, [{binary, binary}]}
          ]
    @callback presigned_url(
                config :: map,
                http_method :: atom,
                bucket :: binary,
                object :: binary,
                opts :: presigned_url_opts
              ) :: {:ok, binary} | {:error, binary}
  end

  def request(conn, %{"uri" => uri, "contentType" => content_type}) do
    {:ok, uri} =
      Api.S3.gen_signed_url(uri, :put, [{"Content-Type", content_type}, {"ACL", "public-read"}])

    conn |> put_status(200) |> json(%{uri: uri})
  end

  def request(conn, %{"uris" => uris}) when is_list(uris) do
    presigned_uris =
      uris
      |> Enum.reduce(%{}, fn %{"uri" => uri, "contentType" => content_type}, acc ->
        case Api.S3.gen_signed_url(uri, :put, [
               {"Content-Type", content_type},
               {"ACL", "public-read"}
             ]) do
          {:ok, signed_uri} ->
            acc |> Map.put(uri, signed_uri)

          e ->
            IO.warn("error: #{e}")
            acc
        end
      end)

    conn |> put_status(200) |> json(%{uris: presigned_uris})
  end
end
