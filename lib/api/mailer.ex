defmodule Api.Mailer do
  @moduledoc """
  This module is responsible for email sending.
  All of its API is documented on the Bamboo docs: https://hexdocs.pm/bamboo/Bamboo.Mailer.html
  """
  use Bamboo.Mailer, otp_app: :api
end
