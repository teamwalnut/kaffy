defmodule ApiWeb.GraphQL.FindAndReplaceJobTest do
  use ApiWeb.GraphQLCase
  use Oban.Testing, repo: Api.Repo

  load_gql(
    :start_find_and_replace_job,
    ApiWeb.Schema,
    "test/support/mutations/async_jobs/StartFindAndRepalceJob.gql"
  )

  load_gql(
    :check_find_and_replace_job,
    ApiWeb.Schema,
    "test/support/queries/async_jobs/CheckFindAndReplaceJob.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen
  ]

  describe "find and replace asynchronous job" do
    @tag :skip
    test "queue new job", %{
      context: context,
      user: _user,
      public_storyline: %{id: storyline_id} = _storyline
    } do
      assert %{"id" => job_id, "queuedAt" => queued_at} =
               query(
                 :start_find_and_replace_job,
                 %{
                   "storylineId" => storyline_id,
                   "from" => "hello",
                   "to" => "world"
                 },
                 context
               )
               |> get_in(["startFindAndReplaceJob"])

      assert_enqueued(
        worker: "AsyncJobs.FindAndReplace",
        args: %{
          "id" => job_id,
          "find_term" => "hello",
          "replace_term" => "world",
          "storyline_id" => storyline_id
        }
      )

      assert %{"id" => ^job_id, "queuedAt" => ^queued_at} =
               query(
                 :check_find_and_replace_job,
                 %{"jobId" => job_id},
                 context
               )
               |> get_in(["checkFindAndReplaceJobStatus"])
    end
  end

  defp query(query, variables, context) do
    assert {:ok, query_data} = query_gql_by(query, variables: variables, context: context)
    no_errors!(query_data)
    get_in(query_data, [:data])
  end
end
