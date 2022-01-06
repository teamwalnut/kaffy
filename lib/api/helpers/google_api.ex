defmodule Api.GoogleApi do
  @moduledoc """
  Helpers class to interact with Google Apis, specifically for user login
  """
  defmodule Behaviour do
    @moduledoc false
    @callback token_info(token :: binary) ::
                {:ok, map}
                | {:error, %{status_code: pos_integer, body: binary}}
  end

  # coveralls-ignore-start

  defmodule Api do
    @moduledoc false
    @behaviour Behaviour
    def token_info(token) do
      {:ok, resp} = Mojito.get("https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=#{token}")

      case resp do
        %Mojito.Response{status_code: 200, body: body} ->
          {:ok, Jason.decode!(body)}

        %Mojito.Response{status_code: status_code, body: body} ->
          {:error, %{status_code: status_code, body: body}}
      end
    end
  end

  # coveralls-ignore-stop

  @google_api Application.compile_env(:api, __MODULE__)[:api]
  def token_info(token) do
    @google_api.token_info(token)
  end
end
