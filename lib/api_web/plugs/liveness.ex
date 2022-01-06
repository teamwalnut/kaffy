defmodule ApiWeb.Plugs.Liveness do
  @moduledoc """
  Simple resp plug to be used as a live-check, it simply replies with `default_resp`.
  This is used to monitor our servers availability from various platform(k8s for example)
  """
  import Plug.Conn

  def init(opts) do
    %{
      path: Keyword.get(opts, :path, default_path()),
      resp: Keyword.get(opts, :resp, default_resp())
    }
  end

  def call(%Plug.Conn{request_path: path} = conn, %{path: path, resp: resp}) do
    conn
    |> send_resp(200, resp)
    |> halt()
  end

  def call(conn, _opts), do: conn

  defp default_path, do: Application.get_env(:healthchex, :liveness_path, "/ping")
  defp default_resp, do: Application.get_env(:healthchex, :liveness_response, "OK")
end
