defmodule ApiWeb.Engagement do
  alias Api.Repo
  alias Api.Storylines.Storyline

  @moduledoc """
  Centralizes our engagement metrics processing
  """
  defmodule Provider do
    def make do
      Application.get_env(:api, :engagement)
    end

    defmodule Behaviour do
      @moduledoc false
      @callback query(
                  query_name :: atom,
                  params :: map
                ) :: tuple

      @callback generate_chart_url(
                  query_name :: atom,
                  params :: map
                ) :: String.t()
    end

    @behaviour Behaviour
    def query(query_name, params) do
      Api.Metabase.query(query_name, params)
    end

    def generate_chart_url(query_name, params) do
      Api.Metabase.generate_chart_url(query_name, params)
    end
  end

  defmodule Metrics do
    defmodule Storylines do
      @moduledoc false
      def time_spent(storyline_id, from_date, actor) do
        storyline = Storyline |> Repo.get!(storyline_id)

        with :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
          Provider.make().query(
            :storyline_time_spent,
            %{"storyline_ids" => [storyline_id], "from" => from_date}
          )
        end
      end

      def screen_completion(storyline_id, from_date, actor) do
        storyline = Storyline |> Repo.get!(storyline_id)

        with :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
          Provider.make().query(
            :storyline_screen_completion,
            %{"storyline_ids" => [storyline_id], "from" => from_date}
          )
        end
      end
    end

    defmodule Flows do
      @moduledoc false
      def time_spent(storyline_id, from_date, actor) do
        storyline = Storyline |> Repo.get!(storyline_id)

        with :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
          Provider.make().query(
            :flows_time_spent,
            %{"storyline_ids" => [storyline_id], "from" => from_date}
          )
        end
      end

      def screen_completion(storyline_id, from_date, actor) do
        storyline = Storyline |> Repo.get!(storyline_id)

        with :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
          Provider.make().query(
            :flows_screen_completion,
            %{"storyline_ids" => [storyline_id], "from" => from_date}
          )
        end
      end
    end

    defmodule Demos do
      @moduledoc false
      def time_spent(demo_ids, from_date) do
        Provider.make().query(
          :demos_time_spent,
          %{"demo_ids" => demo_ids, "from" => from_date}
        )
      end

      def screen_completion(demo_ids, from_date) do
        Provider.make().query(
          :demos_screen_completion,
          %{"demo_ids" => demo_ids, "from" => from_date}
        )
      end
    end
  end

  defmodule Activity do
    defmodule Storylines do
      @moduledoc false
      def list_all(storyline_id, from_date, actor) do
        storyline = Storyline |> Repo.get!(storyline_id)

        with :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
          Provider.make().query(
            :storyline_demos_activity,
            %{"storyline_ids" => [storyline_id], "from" => from_date}
          )
        end
      end
    end
  end

  defmodule Charts do
    defmodule Storylines do
      @moduledoc false
      def demos_visits(storyline_id, from_date, actor) do
        storyline = Storyline |> Repo.get!(storyline_id)

        with :ok <- Api.Authorizer.authorize(storyline, actor, :viewer) do
          chart = %{
            name: :demos_visits |> Atom.to_string(),
            src:
              Provider.make().generate_chart_url(
                :demos_visits,
                %{"storyline_ids" => [storyline_id], "from" => from_date}
              )
          }

          {:ok, chart}
        end
      end
    end
  end
end
