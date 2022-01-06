defmodule Api.ExAwsHttpClient do
  @moduledoc false
  @behaviour ExAws.Request.HttpClient
  def request(method, url, body, headers, _http_opts) do
    case Mojito.request(method, url, headers, body) do
      {:ok, %Mojito.Response{status_code: status_code, body: body}} ->
        {:ok, %{status_code: status_code, body: body}}

      {:error, %Mojito.Error{reason: reason}} ->
        {:error, %{reason: reason}}
    end
  end
end
