defmodule ApiWeb.GraphQL.StorylineActivity do
  use ApiWeb.GraphQLCase

  load_gql(ApiWeb.Schema, "test/support/queries/StorylineActivity.gql")

  setup [
    :register_and_log_in_member,
    :setup_public_storyline
  ]

  describe "storyline activity" do
    test "lists activity for a storyline", %{
      context: context,
      user: _user,
      public_storyline:
        %{
          id: storyline_id,
          name: storyline_name
        } = _storyline
    } do
      demo_uuid = Ecto.UUID.generate()
      demo_name = "Default"

      ApiWeb.Engagement.ProviderMock
      |> expect(
        :query,
        fn :storyline_demos_activity, %{"storyline_ids" => [^storyline_id]} ->
          {:ok,
           [
             %{
               action: "View",
               id: Ecto.UUID.generate(),
               demo_name: demo_name,
               demo_uuid: demo_uuid,
               storyline_name: storyline_name,
               storyline_uuid: storyline_id,
               timestamp: "2021-05-21T22:37:28.894Z",
               user_id: "admin@walnut.io"
             },
             %{
               action: "View",
               context_page_path: "/demo/",
               id: Ecto.UUID.generate(),
               demo_name: demo_name,
               demo_uuid: demo_uuid,
               storyline_name: storyline_name,
               storyline_uuid: storyline_id,
               time_spent_since_last_event: nil,
               timestamp: "2021-05-21T22:25:57.122Z",
               user_id: nil
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
                 "storylineActivity" => [
                   %{
                     "action" => "View",
                     "demoName" => ^demo_name,
                     "demoUuid" => ^demo_uuid,
                     "id" => _,
                     "storylineName" => ^storyline_name,
                     "storylineUuid" => ^storyline_id,
                     "timestamp" => "2021-05-21T22:37:28.894Z",
                     "userId" => "admin@walnut.io"
                   },
                   %{
                     "action" => "View",
                     "demoName" => ^demo_name,
                     "demoUuid" => ^demo_uuid,
                     "id" => _,
                     "storylineName" => ^storyline_name,
                     "storylineUuid" => ^storyline_id,
                     "timestamp" => "2021-05-21T22:25:57.122Z",
                     "userId" => nil
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
        fn :storyline_demos_activity, %{"storyline_ids" => [^storyline_id]} -> {:ok, []} end
      )

      assert {:ok, query_data} =
               query_gql(
                 variables: %{"storylineId" => storyline_id},
                 context: context
               )

      no_errors!(query_data)

      assert %{data: %{"storylineActivity" => []}} = query_data
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
             request: nil,
             request_url: nil,
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
                        data: %{"storylineActivity" => nil},
                        errors: [
                          %{
                            code: :unknown,
                            message: "Something went wrong",
                            path: ["storylineActivity"],
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
                        data: %{"storylineActivity" => nil},
                        errors: [
                          %{
                            code: :nxdomain,
                            message: "nxdomain",
                            path: ["storylineActivity"],
                            status_code: 422
                          }
                        ]
                      } = query_data
             end) =~ "Unhandled error code: :nxdomain"
    end
  end
end
