defmodule ApiWeb.GraphQL.UpdateDemoIsShared do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :update_demo_is_shared,
    ApiWeb.Schema,
    "test/support/mutations/demos/UpdateDemoIsShared.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "UpdateDemoIsShared" do
    test "it updates a demo for being shared", %{
      context: %{current_user: %{email: user_email}} = context,
      member: member,
      public_storyline: %{id: storyline_id} = storyline
    } do
      %{demo: demo} = storyline |> demo_fixture(member)

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "demo_sharing_updated",
                           %{demo: _demo_id, storyline: ^storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_demo_is_shared,
                 variables: %{
                   "demoId" => demo.id,
                   "isShared" => true
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "updateDemoIsShared"])
      assert result["id"] != nil
      assert result["isShared"] == true
    end

    test "authorization", %{
      context: context,
      member: member,
      public_storyline: storyline
    } do
      %{demo: demo} = storyline |> demo_fixture(member)

      TestAccess.assert_roles(
        &query_gql_by(
          :update_demo_is_shared,
          variables: %{"demoId" => demo.id, "isShared" => true},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end

  test "it updates a demo for being non shared", %{
    context: %{current_user: %{email: user_email}} = context,
    member: member,
    public_storyline: %{id: storyline_id} = storyline
  } do
    %{demo: demo} = storyline |> demo_fixture(member)

    ApiWeb.Analytics.ProviderMock
    |> expect(:track, fn ^user_email,
                         "demo_sharing_updated",
                         %{demo: _demo_id, storyline: ^storyline_id} ->
      :ok
    end)

    assert {:ok, query_data} =
             query_gql_by(
               :update_demo_is_shared,
               variables: %{
                 "demoId" => demo.id,
                 "isShared" => false
               },
               context: context
             )

    no_errors!(query_data)
    result = get_in(query_data, [:data, "updateDemoIsShared"])
    assert result["id"] != nil
    assert result["isShared"] == false
  end
end
