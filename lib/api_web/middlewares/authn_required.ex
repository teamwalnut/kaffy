defmodule ApiWeb.Middlewares.AuthnRequired do
  @moduledoc false
  @behaviour Absinthe.Middleware
  alias Api.Accounts.User
  alias Api.Companies.Member

  def call(resolution, _config) do
    case resolution.context do
      %{current_member: %Member{}} ->
        resolution

      %{current_user: %User{}} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, :unauthorized})
    end
  end
end
