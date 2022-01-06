defmodule ApiWeb.Schema.BusinessIntegrationTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias Api.Repo
  alias Api.Storylines.Demos.Demo
  alias ApiWeb.Engagement.Metrics
  alias ApiWeb.Middlewares

  object :demo_metrics do
    field(:storyline_uuid, non_null(:id))
    field(:storyline_name, non_null(:string))
    field(:uuid, non_null(:id))
    field(:name, non_null(:string))
    field(:started, non_null(:integer))
    field(:bounced, non_null(:integer))
    field(:total_visits, non_null(:integer))
    field(:unique_visitors, non_null(:integer))
    field(:avg_screen_completion, non_null(:float))
    field(:avg_time_spent, non_null(:string))
    field(:avg_time_spent_milliseconds, non_null(:float))
  end

  object :business_integration_queries do
    @desc """
    Lists demos metrics
    """
    field :member_demos_metrics, list_of(non_null(:demo_metrics)) do
      middleware(Middlewares.AuthnRequired)
      arg(:from, :float)

      resolve(fn _parent, args, %{context: %{current_member: actor}} ->
        from_date = args |> Map.get(:from) |> parse_timestamp()
        demo_ids = actor.user |> member_demo_ids

        with {:ok, time_spent_rows} <-
               Metrics.Demos.time_spent(demo_ids, from_date),
             {:ok, screen_completion_rows} <-
               Metrics.Demos.screen_completion(demo_ids, from_date) do
          {:ok, time_spent_rows |> merge_lists(screen_completion_rows)}
        end
      end)
    end
  end

  defp member_demo_ids(current_user) do
    member = Api.Companies.member_from_user(current_user.id)

    storylines =
      Api.Storylines.list_all_storylines(member.id, member.company_id)
      |> Repo.preload(demos: Demo.ordered_query())

    storylines
    |> Enum.flat_map(fn storyline -> storyline.demos end)
    |> Enum.map(fn demo -> demo.id end)
  end

  defp merge_lists(list_a, list_b) do
    for item_a <- list_a do
      Map.merge(
        item_a,
        Enum.find(list_b, fn item_b ->
          item_a[:uuid] == item_b[:uuid]
        end)
      )
    end
  end

  defp parse_timestamp(nil), do: nil

  defp parse_timestamp(timestamp) do
    trunc(timestamp)
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_date()
    |> Date.to_string()
  end
end
