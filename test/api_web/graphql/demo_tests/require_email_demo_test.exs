defmodule ApiWeb.GraphQL.UpdateDemoRequireEmail do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :update_demo_gate,
    ApiWeb.Schema,
    "test/support/mutations/demos/UpdateDemoRequireEmail.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "UpdateDemoRequireEmail" do
    test "it updates a demo to require email to open a demo", %{
      context: %{current_user: %{email: _user_email}} = context,
      member: member,
      public_storyline: %{id: _storyline_id} = storyline
    } do
      %{demo: demo} = storyline |> demo_fixture(member)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_demo_gate,
                 variables: %{
                   "id" => demo.id,
                   "isEmailRequired" => true
                 },
                 context: context
               )

      no_errors!(query_data)
      result = get_in(query_data, [:data, "updateDemoGate"])
      assert result["id"] != nil
      assert result["emailRequired"] == true
    end

    test "authorization", %{context: context, member: member, public_storyline: storyline} do
      %{demo: demo} = storyline |> demo_fixture(member)

      TestAccess.assert_roles(
        &query_gql_by(
          :update_demo_gate,
          variables: %{"id" => demo.id, "isEmailRequired" => true},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end

  test "it updates a demo for not requiring email to open a demo", %{
    context: %{current_user: %{email: _user_email}} = context,
    member: member,
    public_storyline: %{id: _storyline_id} = storyline
  } do
    %{demo: demo} = storyline |> demo_fixture(member)

    assert {:ok, query_data} =
             query_gql_by(
               :update_demo_gate,
               variables: %{
                 "id" => demo.id,
                 "isEmailRequired" => false
               },
               context: context
             )

    no_errors!(query_data)
    result = get_in(query_data, [:data, "updateDemoGate"])
    assert result["id"] != nil
    assert result["emailRequired"] == false
  end
end
