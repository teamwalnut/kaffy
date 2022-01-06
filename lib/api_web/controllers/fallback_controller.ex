defmodule ApiWeb.FallbackController do
  @moduledoc """
  Fallback controller for Phoenix, makes sure we always return structured errors
  using the Error Util.
  """
  use ApiWeb, :controller

  alias ApiWeb.Utils.Error

  def call(conn, error) do
    errors =
      error
      |> Error.normalize()
      |> List.wrap()

    status = hd(errors).status_code
    messages = Enum.map(errors, & &1.message)

    conn
    |> put_status(status)
    |> json(%{errors: messages})
  end
end
