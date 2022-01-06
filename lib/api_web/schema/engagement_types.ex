defmodule ApiWeb.Schema.EngagementTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias ApiWeb.Engagement.{Activity, Charts, Metrics}
  alias ApiWeb.Middlewares

  object :storyline_metrics do
    field(:storyline_uuid, non_null(:string))
    field(:storyline_name, non_null(:string))
    field(:total_visits, non_null(:integer))
    field(:unique_visitors, non_null(:integer))
    field(:avg_screen_completion, non_null(:float))
    field(:total_time_spent, non_null(:string))
    field(:avg_time_spent, non_null(:string))
    field(:total_hours_spent, non_null(:float))
    field(:avg_hours_spent, non_null(:float))
    field(:bounces, non_null(:integer))
  end

  object :flow_metrics do
    field(:flow_name, non_null(:string))
    field(:unique_visitors, non_null(:integer))
    field(:avg_screen_completion, non_null(:float))
    field(:total_time_spent, non_null(:string))
    field(:avg_time_spent, non_null(:string))
    field(:total_hours_spent, non_null(:float))
    field(:avg_hours_spent, non_null(:float))
  end

  object :storyline_activity do
    field(:id, non_null(:string))
    field(:timestamp, non_null(:string))
    field(:action, non_null(:string))
    field(:user_id, :string)
    field(:storyline_uuid, non_null(:string))
    field(:storyline_name, non_null(:string))
    field(:demo_uuid, non_null(:string))
    field(:demo_name, non_null(:string))
    field(:demo_gate_provided_email, :string)
  end

  object :storyline_chart do
    field(:name, non_null(:string))
    field(:src, non_null(:string))
  end

  object :engagement_queries do
    @desc """
    Lists storyline metrics
    """
    field :storyline_metrics, list_of(non_null(:storyline_metrics)) do
      arg(:storyline_id, non_null(:id))
      arg(:from, :float)

      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent,
                 %{storyline_id: storyline_id} = args,
                 %{context: %{current_member: actor}} ->
        from_date = args |> Map.get(:from) |> parse_timestamp()

        with {:ok, time_spent_rows} <-
               Metrics.Storylines.time_spent(storyline_id, from_date, actor),
             {:ok, screen_completion_rows} <-
               Metrics.Storylines.screen_completion(storyline_id, from_date, actor) do
          {:ok, time_spent_rows |> merge_sorted_lists(screen_completion_rows)}
        else
          {:error, error} -> {:error, error}
        end
      end)
    end

    @desc """
    Lists storyline flows metrics
    """
    field :storyline_flows_metrics, list_of(non_null(:flow_metrics)) do
      arg(:storyline_id, non_null(:id))
      arg(:from, :float)

      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent,
                 %{storyline_id: storyline_id} = args,
                 %{context: %{current_member: actor}} ->
        from_date = args |> Map.get(:from) |> parse_timestamp()

        with {:ok, time_spent_rows} <-
               Metrics.Flows.time_spent(storyline_id, from_date, actor),
             {:ok, screen_completion_rows} <-
               Metrics.Flows.screen_completion(storyline_id, from_date, actor) do
          {:ok, time_spent_rows |> merge_sorted_lists(screen_completion_rows)}
        else
          {:error, error} -> {:error, error}
        end
      end)
    end

    @desc """
    Lists storyline activity
    """
    field :storyline_activity, list_of(non_null(:storyline_activity)) do
      arg(:storyline_id, non_null(:id))
      arg(:from, :float)

      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent,
                 %{storyline_id: storyline_id} = args,
                 %{context: %{current_member: actor}} ->
        from_date = args |> Map.get(:from) |> parse_timestamp()

        case Activity.Storylines.list_all(storyline_id, from_date, actor) do
          {:ok, activity_rows} -> {:ok, activity_rows}
          {:error, error} -> {:error, error}
        end
      end)
    end

    @desc """
    Lists storyline metrics
    """
    field :storyline_charts, list_of(non_null(:storyline_chart)) do
      arg(:storyline_id, non_null(:id))
      arg(:from, :float)

      resolve(fn _parent,
                 %{storyline_id: storyline_id} = args,
                 %{context: %{current_member: actor}} ->
        from_date = args |> Map.get(:from) |> parse_timestamp()

        case Charts.Storylines.demos_visits(storyline_id, from_date, actor) do
          {:ok, chart} -> {:ok, [chart]}
        end
      end)
    end
  end

  # merge sorted lists of maps
  defp merge_sorted_lists(list_a, list_b) do
    for {item_a, item_b} <- Enum.zip(list_a, list_b) do
      Map.merge(item_a, item_b)
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
