defmodule ApiWeb.GraphQL.StorylineMetrics do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/StorylineMetrics.gql")

  setup [
    :register_and_log_in_member,
    :setup_public_storyline
  ]

  describe "storyline metrics" do
    test "lists all metrics for a storyline", %{
      context: context,
      user: _user,
      public_storyline:
        %{
          id: storyline_id,
          name: storyline_name
        } = _storyline
    } do
      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :storyline_time_spent, %{"storyline_ids" => [^storyline_id]} ->
          {:ok,
           [
             %{
               storyline_name: storyline_name,
               storyline_uuid: storyline_id,
               avg_time_spent: "0 years 0 mons 0 days 0 hours 1 mins 40.256789 secs",
               total_time_spent: "0 years 0 mons 0 days 1 hours 3 mins 29.758 secs",
               total_visits: 43,
               unique_visitors: 38
             }
           ]}
        end
      )

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :storyline_screen_completion, %{"storyline_ids" => [^storyline_id]} ->
          {:ok,
           [
             %{
               avg_screen_completion: 0.8,
               storyline_uuid: storyline_id
             }
           ]}
        end
      )

      assert {:ok, query_data} =
               query_gql(
                 variables: %{
                   "storylineId" => storyline_id
                 },
                 context: context
               )

      no_errors!(query_data)

      assert %{
               data: %{
                 "storylineMetrics" => [
                   %{
                     "avgScreenCompletion" => 0.8,
                     "avgTimeSpent" => "0 years 0 mons 0 days 0 hours 1 mins 40.256789 secs",
                     "storylineName" => ^storyline_name,
                     "storylineUuid" => ^storyline_id,
                     "totalTimeSpent" => "0 years 0 mons 0 days 1 hours 3 mins 29.758 secs",
                     "uniqueVisitors" => 38,
                     "totalVisits" => 43
                   }
                 ]
               }
             } = query_data
    end

    test "empty results", %{
      context: context,
      user: _user,
      public_storyline: %{id: storyline_id} = _storyline
    } do
      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :storyline_time_spent, %{"storyline_ids" => [^storyline_id]} -> {:ok, []} end
      )

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :storyline_screen_completion, %{"storyline_ids" => [^storyline_id]} -> {:ok, []} end
      )

      assert {:ok, query_data} =
               query_gql(
                 variables: %{
                   "storylineId" => storyline_id
                 },
                 context: context
               )

      no_errors!(query_data)

      assert %{data: %{"storylineMetrics" => []}} = query_data
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
                        data: %{"storylineMetrics" => nil},
                        errors: [
                          %{
                            code: :unknown,
                            message: "Something went wrong",
                            path: ["storylineMetrics"],
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
                        data: %{"storylineMetrics" => nil},
                        errors: [
                          %{
                            code: :nxdomain,
                            message: "nxdomain",
                            path: ["storylineMetrics"],
                            status_code: 422
                          }
                        ]
                      } = query_data
             end) =~ "Unhandled error code: :nxdomain"
    end
  end
end
