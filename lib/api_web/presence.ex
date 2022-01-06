defmodule ApiWeb.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :api,
    pubsub_server: Api.PubSub
end
