defmodule ApiWeb.GraphQL.RepositionGuide do
  use ApiWeb.GraphQLCase
  alias Api.Annotations
  alias Api.TestAccess

  load_gql(
    :reposition_guide,
    ApiWeb.Schema,
    "test/support/mutations/annotations/RepositionGuide.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline
  ]

  describe "RepositionGuide" do
    test "it repositions a guide to a new position", %{
      public_storyline: public_storyline,
      context: context,
      member: member
    } do
      _guide_1 = Annotations.list_guides(public_storyline.id) |> Enum.at(0)
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, _guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_guide,
                 variables: %{
                   "id" => guide_2.id,
                   "newPriority" => 0
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "repositionGuide"])
      assert result["id"] == guide_2.id
      assert result["priority"] == 0
    end

    test "it fails to reposition an annotation to an invalid (OFB) priority", %{
      public_storyline: public_storyline,
      context: context,
      member: member
    } do
      _guide_1 = Annotations.list_guides(public_storyline.id) |> Enum.at(0)
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, _guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_guide,
                 variables: %{
                   "id" => guide_2.id,
                   "newPriority" => 4
                 },
                 context: context
               )

      error = get_in(query_data, [:errors]) |> Enum.at(0)
      assert error[:message] == "The new priority position is out of bounds"
    end

    test "it fails to reposition an annotation to an invalid (negative) priority", %{
      public_storyline: public_storyline,
      context: context,
      member: member
    } do
      _guide_1 = Annotations.list_guides(public_storyline.id) |> Enum.at(0)
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, _guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      assert {:ok, query_data} =
               query_gql_by(
                 :reposition_guide,
                 variables: %{
                   "id" => guide_2.id,
                   "newPriority" => -1
                 },
                 context: context
               )

      error = get_in(query_data, [:errors]) |> Enum.at(0)
      assert error[:message] == "Something went wrong"
    end

    test "authorization", %{
      public_storyline: public_storyline,
      context: context,
      member: member
    } do
      _guide_1 = Annotations.list_guides(public_storyline.id) |> Enum.at(0)
      {:ok, guide_2} = Annotations.create_guide(public_storyline.id, %{name: "Guide 2"}, member)
      {:ok, _guide_3} = Annotations.create_guide(public_storyline.id, %{name: "Guide 3"}, member)

      TestAccess.assert_roles(
        &query_gql_by(
          :reposition_guide,
          variables: %{
            "id" => guide_2.id,
            "newPriority" => 0
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
