defmodule Api.S3 do
  @moduledoc """
  Wrapper for accessing S3 buckets
  """

  defmodule API do
    @moduledoc """
    Contract for S3 API, currently used for mocking
    """
    @type presigned_url_opts :: [
            {:expires_in, integer}
            | {:virtual_host, boolean}
            | {:query_params, [{binary, binary}]}
          ]
    @callback gen_signed_url(
                asset :: binary,
                method :: atom | nil,
                headers :: [{binary, binary}] | nil,
                expiration :: integer | nil
              ) ::
                {:ok, binary} | {:error, binary}

    @callback gen_signed_url(
                asset :: binary,
                method :: atom
              ) ::
                {:ok, binary} | {:error, binary}
  end

  @behaviour API
  @twenty_min_expiration_in_secs 60 * 10 * 2

  def gen_signed_url(
        asset,
        method \\ :get,
        headers \\ [],
        expiration \\ @twenty_min_expiration_in_secs
      ) do
    config = ExAws.Config.new(:s3)

    ExAws.S3.presigned_url(config, method, bucket_name(), asset,
      query_params: headers,
      s3_accelerate: !config[:local],
      expires_in: expiration
    )
  end

  defp bucket_name do
    Application.get_env(:api, :s3)[:bucket_name]
  end
end
