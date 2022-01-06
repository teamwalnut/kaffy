defmodule AsyncJobs.FindAndReplace do
  @moduledoc false
  # alias Api.Repo
  use Oban.Worker, queue: :default

  defmodule Request do
    @moduledoc false
    @derive Jason.Encoder
    defstruct [
      :storyline_id,
      :find_term,
      :replace_term
    ]
  end

  defmodule Descriptor do
    @moduledoc false
    use Api.Schema

    # NOTE(@ostera): it would be easier to have one job table per kind of job
    # so we don't need to introduce an untyped blob of data that may require
    # different validation depending on another column (eg. if job_name ==
    # "find_and_replace" then validate else ...)
    schema "jobs" do
      field(:job_name, :string)
      field(:status, Ecto.Enum, values: [:pending, :in_progress, :finished])
      timestamps()
    end

    def changeset(desc \\ %__MODULE__{}, attrs) do
      desc
      |> cast(attrs, [:id, :job_name, :status])
    end
  end

  @doc """

  The main API to queue FindAndReplace operations.

  Example:

  > req = %AsyncJobs.FindAndReplace.Request{ storyline_id: 1 }
  > {:ok, jd} = AsyncJobs.FindAndReplace.queue(req)
  > AsyncJobs.FindAndReplace.check(jd.id)

  """
  def queue(%Request{} = _req) do
    # job_id = Ecto.UUID.generate()

    # {:ok, descriptor} =
    #   %{id: job_id, job_name: "find_and_replace", status: :pending}
    #   |> Descriptor.changeset()
    #   |> Repo.insert()

    # {:ok, _} =
    #   req
    #   |> Map.from_struct()
    #   |> Map.put(:id, job_id)
    #   |> __MODULE__.new()
    #   |> Oban.insert()

    # {:ok, descriptor}
    {:error, :job_not_found}
  end

  def check(_id) do
    {:error, :job_not_found}
    # case Repo.get(Descriptor, id) do
    #   nil -> {:error, :job_not_found}
    #   %Descriptor{} = jd -> {:ok, jd}
    # end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(30)

  # NOTE(@ostera): this is the function that will actually run the job.
  # This function is currently faking a long-process by spawning a
  # process, and having that process wait here and there until it is
  # done.
  #
  # The important part is that those `send` calls are sending messages
  # back into the process that is currently executing the job, so we
  # can use a good old `receive` expression to get them.
  #
  # This is what the `loop/2` function does. It just receives the
  # messages and updates the table where we persist the current
  # FindAndReplace status.
  #
  @impl Oban.Worker
  def perform(%Oban.Job{args: _req} = _job) do
    # jd = Repo.get!(Descriptor, req["id"])
    # job_pid = self()

    # Process.spawn(
    #   fn ->
    #     send(job_pid, :started)
    #     :timer.sleep(2000)

    #     for n <- 1..10 do
    #       send(job_pid, {:progress, n})
    #       :timer.sleep(500)
    #     end

    #     send(job_pid, :finished)
    #   end,
    #   [:link]
    # )

    # loop(jd, job)
    :do_business
  end

  # def loop(req, job) do
  #   receive do
  #     :started ->
  #       {:ok, req} =
  #         Descriptor.changeset(req, %{status: :in_progress})
  #         |> Repo.update()

  #       loop(req, job)

  #     {:progress, _} ->
  #       {:ok, req} =
  #         Descriptor.changeset(req, %{status: :in_progress})
  #         |> Repo.update()

  #       loop(req, job)

  #     :finished ->
  #       {:ok, _} =
  #         Descriptor.changeset(req, %{status: :finished})
  #         |> Repo.update()

  #       :ok
  #   after
  #     60_000 ->
  #       raise RuntimeError, "Is this job stuck? #{job}"
  #   end
  # end
end
