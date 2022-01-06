defmodule ApiWeb.GraphQL.FeaturesFlagsTest do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/FeaturesFlags.gql")

  describe "FeaturesFlags" do
    setup [:register_and_log_in_user, :setup_company, :setup_member]

    test "Without login, should return nil" do
      result = query_gql()
      assert {:ok, query_data} = result

      features_flags = get_in(query_data, [:data, "featuresFlags"])
      assert is_nil(features_flags)
    end

    test "it should return features flags for logged in user", %{context: context} do
      result = query_gql(variables: %{}, context: context)
      assert {:ok, query_data} = result
      features_flags = get_in(query_data, [:data, "featuresFlags"])

      assert features_flags == %{
               "autoLink" => true,
               "multipleResolutions" => false,
               "logLevel" => "WARNING"
             }

      errors = get_in(query_data, [:errors])
      refute errors
    end
  end
end
