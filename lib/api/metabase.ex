defmodule Api.Metabase do
  @moduledoc """
  Metabase query service, used to fetch metrics
  """
  @headers [
    {"Content-Type", "application/json"}
  ]

  @options [
    {:recv_timeout, 15_000}
  ]

  @doc """
  fetch embed metabase card query results

  ## Examples

    iex> query(
            :storyline_screen_completion,
            %{"storyline_id" => storyline_id}
          )
    {:ok, %{}}

    iex> query(
            :storyline_screen_completion,
            %{"wrong_param_name" => param_value}
          )
    {:error, %HTTPoison.Response{}}
  """
  def query(query_name, params) do
    case HTTPoison.get(
           generate_query_url(query_name, params),
           @headers,
           @options
         ) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        case status_code do
          202 -> {:ok, Jason.decode!(body) |> parse_resp}
          _ -> {:error, %HTTPoison.Response{status_code: status_code, body: body}}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  generates embed metabase chart jwt tokenized url
  """
  def generate_chart_url(chart_name, params) do
    chart_id = Application.get_env(:api, :metabase)[:chart_id_by_name][chart_name]
    token = generate_jwt_token(chart_id, params)
    "https://walnut.metabaseapp.com/embed/question/#{token}#bordered=false&titled=false"
  end

  defp generate_query_url(query_name, params) do
    query_id = Application.get_env(:api, :metabase)[:query_id_by_name][query_name]
    token = generate_jwt_token(query_id, params)
    "https://walnut.metabaseapp.com/api/embed/card/#{token}/query"
  end

  defp generate_jwt_token(query_id, params) do
    key = Application.get_env(:api, :metabase)[:jwt_key]
    signer = key |> Api.JWT.signer()

    extra_claims = %{
      "resource" => %{"question" => query_id},
      "params" => params
    }

    Api.JWT.generate_and_sign!(extra_claims, signer)
  end

  defp parse_resp(%{"data" => %{"rows" => rows, "cols" => cols}} = _body) do
    rows
    |> Enum.map(fn row ->
      cols
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {col, index}, acc ->
        acc
        |> Map.put(
          col["display_name"] |> String.to_atom(),
          row |> Enum.at(index)
        )
      end)
    end)
  end
end
