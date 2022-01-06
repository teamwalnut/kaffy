defmodule ApiWeb.Schema.AsyncJobs.FindAndReplaceTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias ApiWeb.Middlewares

  object :find_and_replace_pending do
    field :id, non_null(:id)

    field :queued_at, non_null(:datetime) do
      resolve(fn jd, _, _ -> {:ok, jd.inserted_at} end)
    end
  end

  object :find_and_replace_in_progress do
    field :id, non_null(:id)
  end

  object :find_and_replace_success do
    field :id, non_null(:id)
  end

  union :find_and_replace_job_descriptor do
    types([
      :find_and_replace_pending,
      :find_and_replace_in_progress,
      :find_and_replace_success
    ])

    resolve_type(fn
      %AsyncJobs.FindAndReplace.Descriptor{status: :pending}, _ ->
        :find_and_replace_pending

      %AsyncJobs.FindAndReplace.Descriptor{status: :in_progress}, _ ->
        :find_and_replace_in_progress

      %AsyncJobs.FindAndReplace.Descriptor{status: :finished}, _ ->
        :find_and_replace_success
    end)
  end

  object :async_job_mutations do
    @desc "Start find and replace job"
    field :start_find_and_replace_job, non_null(:find_and_replace_job_descriptor) do
      arg(:storyline_id, non_null(:id))
      arg(:from, non_null(:string))
      arg(:to, non_null(:string))

      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent,
                 %{storyline_id: storyline_id, from: find_term, to: replace_term},
                 _context ->
        req = %AsyncJobs.FindAndReplace.Request{
          storyline_id: storyline_id,
          find_term: find_term,
          replace_term: replace_term
        }

        {:ok, %AsyncJobs.FindAndReplace.Descriptor{}} = AsyncJobs.FindAndReplace.queue(req)
      end)
    end
  end

  object :async_job_queries do
    @desc "Check find and replace job"
    field :check_find_and_replace_job_status, non_null(:find_and_replace_job_descriptor) do
      arg(:job_id, non_null(:id))
      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent, %{job_id: job_id}, _context ->
        {:ok, %AsyncJobs.FindAndReplace.Descriptor{}} = AsyncJobs.FindAndReplace.check(job_id)
      end)
    end
  end
end
