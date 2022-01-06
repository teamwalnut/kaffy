defmodule ApiWeb.GraphQL.MemberDemosMetrics do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/business_integration/MemberDemosMetrics.gql")

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "memeber demos metrics" do
    test "lists all demos metrics for a member", %{
      context: context,
      user: _user,
      member: member,
      public_storyline:
        %{
          id: storyline_id,
          name: storyline_name
        } = storyline
    } do
      %{
        demo: %{
          id: first_demo_id,
          name: first_demo_name
        }
      } = storyline |> demo_fixture(member)

      %{
        demo: %{
          id: second_demo_id,
          name: second_demo_name
        }
      } = storyline |> demo_fixture(member)

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :demos_time_spent, %{"demo_ids" => [^first_demo_id, ^second_demo_id]} ->
          {:ok,
           [
             %{
               storyline_name: storyline_name,
               storyline_uuid: storyline_id,
               name: first_demo_name,
               uuid: first_demo_id,
               started: 15,
               bounced: 18,
               avg_time_spent: "0 years 0 mons 0 days 0 hours 1 mins 40.256789 secs",
               avg_time_spent_milliseconds: 100_000.0,
               total_visits: 33,
               unique_visitors: 28
             },
             %{
               storyline_name: storyline_name,
               storyline_uuid: storyline_id,
               name: second_demo_name,
               uuid: second_demo_id,
               started: 20,
               bounced: 23,
               avg_time_spent: "0 years 0 mons 0 days 0 hours 1 mins 42 secs",
               avg_time_spent_milliseconds: 125_000.0,
               total_visits: 43,
               unique_visitors: 38
             }
           ]}
        end
      )

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :demos_screen_completion, %{"demo_ids" => [^first_demo_id, ^second_demo_id]} ->
          {:ok,
           [
             %{
               avg_screen_completion: 0.8,
               storyline_uuid: storyline_id,
               uuid: first_demo_id
             },
             %{
               avg_screen_completion: 0.6,
               storyline_uuid: storyline_id,
               uuid: second_demo_id
             }
           ]}
        end
      )

      assert {:ok, query_data} = query_gql(variables: %{}, context: context)

      no_errors!(query_data)

      assert %{
               data: %{
                 "memberDemosMetrics" => [
                   %{
                     "storylineName" => ^storyline_name,
                     "storylineUuid" => ^storyline_id,
                     "name" => ^first_demo_name,
                     "uuid" => ^first_demo_id,
                     "started" => 15,
                     "bounced" => 18,
                     "avgScreenCompletion" => 0.8,
                     "avgTimeSpent" => "0 years 0 mons 0 days 0 hours 1 mins 40.256789 secs",
                     "avgTimeSpentMilliseconds" => 100_000.0,
                     "totalVisits" => 33,
                     "uniqueVisitors" => 28
                   },
                   %{
                     "storylineName" => ^storyline_name,
                     "storylineUuid" => ^storyline_id,
                     "name" => ^second_demo_name,
                     "uuid" => ^second_demo_id,
                     "started" => 20,
                     "bounced" => 23,
                     "avgScreenCompletion" => 0.6,
                     "avgTimeSpent" => "0 years 0 mons 0 days 0 hours 1 mins 42 secs",
                     "avgTimeSpentMilliseconds" => 125_000.0,
                     "totalVisits" => 43,
                     "uniqueVisitors" => 38
                   }
                 ]
               }
             } = query_data
    end

    test "empty results", %{
      context: context,
      user: _user,
      member: member,
      public_storyline: storyline
    } do
      %{demo: %{id: first_demo_id}} = storyline |> demo_fixture(member)

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :demos_time_spent, %{"demo_ids" => [^first_demo_id]} -> {:ok, []} end
      )

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :demos_screen_completion, %{"demo_ids" => [^first_demo_id]} -> {:ok, []} end
      )

      assert {:ok, query_data} =
               query_gql(
                 variables: %{},
                 context: context
               )

      no_errors!(query_data)

      assert %{data: %{"memberDemosMetrics" => []}} = query_data
    end

    test "normalizes error response", %{
      context: context,
      user: _user,
      public_storyline: _storyline
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
                          variables: %{},
                          context: context
                        )

               assert %{
                        data: %{"memberDemosMetrics" => nil},
                        errors: [
                          %{
                            code: :unknown,
                            message: "Something went wrong",
                            path: ["memberDemosMetrics"],
                            status_code: 500
                          }
                        ]
                      } = query_data
             end) =~ "You must specify a value for :storyline_ids in the JWT"
    end
  end
end
