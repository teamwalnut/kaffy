defmodule Api.JWT do
  @moduledoc """
  Json web token generator service
  """
  use Joken.Config

  def signer(key) do
    Joken.Signer.create(
      "HS256",
      key
    )
  end
end
