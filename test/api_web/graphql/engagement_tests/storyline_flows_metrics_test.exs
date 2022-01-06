defmodule ApiWeb.GraphQL.StorylineFlowsMetrics do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/StorylineFlowsMetrics.gql")

  setup [
    :register_and_log_in_member,
    :setup_public_storyline
  ]

  describe "storyline flows metrics" do
    test "lists all metrics for a storyline", %{
      context: context,
      user: _user,
      public_storyline: %{id: storyline_id, name: storyline_name} = _storyline
    } do
      default_flow_name = "Default"
      feature_flow_name = "Feature"

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :flows_time_spent, %{"storyline_ids" => [^storyline_id]} ->
          {:ok,
           [
             %{
               flow_name: default_flow_name,
               avg_time_spent: "0 years 0 mons 0 days 0 hours 2 mins 30.247541 secs",
               total_time_spent: "0 years 0 mons 0 days 1 hours 0 mins 5.941 secs",
               unique_visitors: 24
             },
             %{
               flow_name: feature_flow_name,
               avg_time_spent: "0 years 0 mons 0 days 0 hours 0 mins 49.7196 secs",
               total_time_spent: "0 years 0 mons 0 days 0 hours 4 mins 8.598 secs",
               unique_visitors: 5
             }
           ]}
        end
      )

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :flows_screen_completion, %{"storyline_ids" => [^storyline_id]} ->
          {:ok,
           [
             %{
               storyline_uuid: storyline_id,
               storyline_name: storyline_name,
               flow_name: default_flow_name,
               last_num_of_screens: 14,
               num_of_screens_viewes: 154,
               num_of_visitors: 33,
               avg_screen_completion: 0.3333333333333333
             },
             %{
               storyline_uuid: storyline_id,
               storyline_name: storyline_name,
               flow_name: feature_flow_name,
               last_num_of_screens: 14,
               num_of_screens_viewes: 42,
               num_of_visitors: 8,
               avg_screen_completion: 0.375
             }
           ]}
        end
      )

      assert {:ok, query_data} =
               query_gql(
                 variables: %{"storylineId" => storyline_id},
                 context: context
               )

      no_errors!(query_data)

      assert %{
               data: %{
                 "storylineFlowsMetrics" => [
                   %{
                     "avgScreenCompletion" => 0.3333333333333333,
                     "avgTimeSpent" => "0 years 0 mons 0 days 0 hours 2 mins 30.247541 secs",
                     "flowName" => ^default_flow_name,
                     "totalTimeSpent" => "0 years 0 mons 0 days 1 hours 0 mins 5.941 secs",
                     "uniqueVisitors" => 24
                   },
                   %{
                     "avgScreenCompletion" => 0.375,
                     "avgTimeSpent" => "0 years 0 mons 0 days 0 hours 0 mins 49.7196 secs",
                     "flowName" => ^feature_flow_name,
                     "totalTimeSpent" => "0 years 0 mons 0 days 0 hours 4 mins 8.598 secs",
                     "uniqueVisitors" => 5
                   }
                 ]
               }
             } = query_data
    end

    test "returns empty results", %{
      context: context,
      user: _user,
      public_storyline: %{id: storyline_id} = _storyline
    } do
      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :flows_time_spent, %{"storyline_ids" => [^storyline_id]} -> {:ok, []} end
      )

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :flows_screen_completion, %{"storyline_ids" => [^storyline_id]} -> {:ok, []} end
      )

      assert {:ok, query_data} =
               query_gql(
                 variables: %{"storylineId" => storyline_id},
                 context: context
               )

      no_errors!(query_data)

      assert %{data: %{"storylineFlowsMetrics" => []}} = query_data
    end

    test "normalizes error response", %{
      context: context,
      user: _user,
      public_storyline: %{id: storyline_id} = _storyline
    } do
      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        1,
        fn _query_name, _params ->
          {:error,
           %HTTPoison.Response{
             body: "You must specify a value for :storyline_ids in the JWT.",
             headers: [],
             status_code: 400
           }}
        end
      )

      assert capture_log(fn ->
               assert {:ok, query_data} =
                        query_gql(
                          variables: %{"storylineId" => storyline_id},
                          context: context
                        )

               assert %{
                        data: %{"storylineFlowsMetrics" => nil},
                        errors: [
                          %{
                            code: :unknown,
                            message: "Something went wrong",
                            path: ["storylineFlowsMetrics"],
                            status_code: 500
                          }
                        ]
                      } = query_data
             end) =~ "You must specify a value for :storyline_ids in the JWT"
    end

    test "normalizes exception", %{
      context: context,
      user: _user,
      public_storyline: %{id: storyline_id} = _storyline
    } do
      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        1,
        fn _query_name, _params -> {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}} end
      )

      assert capture_log(fn ->
               assert {:ok, query_data} =
                        query_gql(
                          variables: %{"storylineId" => storyline_id},
                          context: context
                        )

               assert %{
                        data: %{"storylineFlowsMetrics" => nil},
                        errors: [
                          %{
                            code: :nxdomain,
                            message: "nxdomain",
                            path: ["storylineFlowsMetrics"],
                            status_code: 422
                          }
                        ]
                      } = query_data
             end) =~ "Unhandled error code: :nxdomain"
    end
  end
end
