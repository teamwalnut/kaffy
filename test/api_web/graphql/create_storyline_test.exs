defmodule ApiWeb.GraphQL.CreateStorylineTest do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(ApiWeb.Schema, "test/support/mutations/CreateStoryline.gql")
  setup [:register_and_log_in_member]

  describe "createStoryline" do
    test "authorization", %{
      context: context,
      company: company
    } do
      admin_user = Api.AccountsFixtures.user_fixture()
      {:ok, admin_member} = Api.Companies.add_member(admin_user.id, company)
      _storyline = Api.StorylinesFixtures.public_storyline_fixture(admin_member)

      TestAccess.assert_roles(
        &query_gql(context: Map.put(context, :current_member, &1)),
        context.current_member,
        %TestAccess{viewer: false, presenter: false, editor: true, company_admin: true}
      )
    end

    test "it should create a new storyline correctly", %{
      context: %{current_user: %{email: user_email}, current_member: member} = context
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "storyline_created",
                           %{url: "https://app.teamwalnut.com/storylines/" <> _storyline_id} ->
        :ok
      end)

      _storyline = Api.StorylinesFixtures.public_storyline_fixture(member)

      result = query_gql(context: context)
      assert {:ok, query_data} = result
      no_errors!(query_data)

      result = get_in(query_data, [:data, "createStoryline"])

      refute is_nil(result["id"])
      assert result["name"] == "New Storyline"
    end
  end
end
