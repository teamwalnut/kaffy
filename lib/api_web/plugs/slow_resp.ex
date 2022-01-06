defmodule ApiWeb.Plugs.SlowResp do
  @moduledoc "Slows down responses to incoming requests"
  @behaviour Plug

  def init(opts) do
    opts[:sleep] || raise("need :sleep option set for #{__MODULE__}")
    is_integer(opts[:sleep]) || raise(":sleep option for #{__MODULE__} needs to be an integer")
    opts
  end

  def call(conn, sleep: milliseconds) do
    :timer.sleep(milliseconds)
    conn
  end
end
