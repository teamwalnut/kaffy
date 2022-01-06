defmodule ApiWeb.UserRegistrationView do
  use ApiWeb, :view

  def render("create.json", %{user: user}) do
    %{user: render_one(user, ApiWeb.UserRegistrationView, "user.json", as: :user)}
  end

  def render("user.json", %{user: user}) do
    %{id: user.id, email: user.email}
  end
end
