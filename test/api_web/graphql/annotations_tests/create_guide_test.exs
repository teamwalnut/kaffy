defmodule ApiWeb.GraphQL.CreateGuide do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  @valid_guide_attributes %{
    name: "Guide 1"
  }
  @invalid_guide_attributes %{
    name: nil
  }

  load_gql(
    :create_guide,
    ApiWeb.Schema,
    "test/support/mutations/annotations/CreateGuide.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :get_default_flow
  ]

  describe "CreateGuide" do
    test "it creates a guide for a storyline when called with valid arguments", %{
      context: %{current_user: %{email: user_email}} = context,
      public_storyline: %{id: storyline_id} = storyline
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "guide_created",
                           %{guide: _guide_id, storyline: ^storyline_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :create_guide,
                 variables: %{
                   "storylineId" => storyline.id,
                   "name" => @valid_guide_attributes[:name]
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "createGuide"])

      assert result["id"] != nil
    end

    test "it fails to create a guide for a storyline when called with invalid arguments", %{
      context: context,
      public_storyline: storyline
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :create_guide,
                 variables: %{
                   "storylineId" => storyline.id,
                   "name" => @invalid_guide_attributes[:name]
                 },
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] == "Argument \"name\" has invalid value $name."
    end

    test "authorization", %{context: context, public_storyline: storyline} do
      TestAccess.assert_roles(
        &query_gql_by(
          :create_guide,
          variables: %{"storylineId" => storyline.id, "name" => @valid_guide_attributes[:name]},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
