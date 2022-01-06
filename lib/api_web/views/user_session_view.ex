defmodule ApiWeb.UserSessionView do
  use ApiWeb, :view

  def render("error.json", %{error_message: error}) do
    %{error: error}
  end

  def render("create.json", %{ok: message}) do
    %{ok: message}
  end

  def render("logout.json", %{ok: message}) do
    %{ok: message}
  end
end
