defmodule ApiWeb.Schema.ScreenGroupingTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers
  alias Api.Storylines
  alias ApiWeb.Middlewares

  @desc "Responsible for organizing a group of screens for a storyline."
  object :flow do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:is_default, non_null(:boolean))
    field(:position, non_null(:integer))
    field(:screens, non_null(list_of(non_null(:screen))), resolve: dataloader(:screen))
  end

  object :flow_mutations do
    @desc "Create a flow for a storyline"
    field :create_flow, non_null(:flow) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:name, non_null(:string))

      resolve(fn _parent,
                 %{storyline_id: storyline_id, name: name},
                 %{context: %{current_member: actor}} ->
        with {:ok, created_flow} <- Storylines.create_flow(storyline_id, %{name: name}, actor) do
          ApiWeb.Analytics.report_flow_created(actor.user, created_flow)
          {:ok, created_flow}
        end
      end)
    end

    @desc "Renames a flow"
    field :rename_flow, non_null(:flow) do
      middleware(Middlewares.AuthnRequired)
      arg(:flow_id, non_null(:id))
      arg(:name, non_null(:string))

      resolve(fn _parent, %{flow_id: flow_id, name: name}, %{context: %{current_member: actor}} ->
        with {:ok, renamed_flow} <- Storylines.rename_flow(flow_id, name, actor) do
          ApiWeb.Analytics.report_flow_renamed(actor.user, renamed_flow)
          {:ok, renamed_flow}
        end
      end)
    end

    @desc "Deletes a flow and moves all of its screens to the default flow of the same storyline"
    field :delete_flow, non_null(:flow) do
      middleware(Middlewares.AuthnRequired)
      arg(:flow_id, non_null(:id))

      resolve(fn _parent, %{flow_id: flow_id}, %{context: %{current_member: actor}} ->
        case Storylines.delete_flow(flow_id, actor) do
          {:ok, deleted_flow} ->
            ApiWeb.Analytics.report_flow_deleted(actor.user, deleted_flow)
            {:ok, deleted_flow}

          {:error, :unauthorized} ->
            {:error, :unauthorized}

          {:error, _} ->
            {:error, "Failed to delete flow #{flow_id}"}
        end
      end)
    end

    @desc "Reposition a flow"
    field :reposition_flow, non_null(list_of(:flow)) do
      middleware(Middlewares.AuthnRequired)
      arg(:flow_id, non_null(:id))
      arg(:new_position, non_null(:integer))

      resolve(fn _parent,
                 %{flow_id: flow_id, new_position: new_position},
                 %{context: %{current_member: actor}} ->
        case Storylines.reposition_flow(flow_id, new_position, actor) do
          {:ok, flows} ->
            flows = flows |> Map.drop(["deferred"]) |> Map.values()
            {:ok, flows}

          err ->
            err
        end
      end)
    end
  end
end
