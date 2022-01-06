defmodule ApiWeb.UserRegistrationViewTest do
  use ApiWeb.ConnCase, async: true

  import Api.AccountsFixtures
  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders create.json" do
    user = user_fixture()

    assert render(ApiWeb.UserRegistrationView, "create.json", %{user: user}) == %{
             user: %{
               email: user.email,
               id: user.id
             }
           }
  end
end
