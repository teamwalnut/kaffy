defmodule ApiWeb.Context do
  @moduledoc """
  Assigns :current_user for each request
  """
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
    current_user =
      case conn.assigns[:current_user] do
        nil ->
          %{}

        %Api.Accounts.User{} = user ->
          member = Api.Companies.member_from_user(user.id) |> Api.Repo.preload([:user, :company])
          %{current_user: user, current_member: member}
      end

    current_user
  end

  def current_user(context)

  def current_user(%{context: %{current_user: current_user}}) do
    current_user
  end

  def current_user(_) do
    nil
  end
end
