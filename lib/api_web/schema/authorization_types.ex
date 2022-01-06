defmodule ApiWeb.Schema.AuthorizationTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias Api.Storylines

  enum :authorization_relationship do
    value(:viewer)
    value(:editor)
    value(:creator)
  end

  enum :resource do
    value(:storyline)
  end

  object :authorization_queries do
    # NOTE(Jaap): server side authorization, this is not used on the frontend yet, but will
    # be used in a next iteration of Roles and Permission.
    field :authorize, non_null(:boolean) do
      arg(:resource, non_null(:resource))
      arg(:id, :id)
      arg(:relationship, non_null(:authorization_relationship))

      resolve(fn
        _,
        %{resource: :storyline, id: id, relationship: relationship},
        %{context: %{current_member: actor}} ->
          with {:ok, storyline} <- Api.Storylines.fetch(id) do
            case Api.Authorizer.authorize(storyline, actor, relationship) do
              :ok -> {:ok, true}
              {:error, :unauthorized} -> {:ok, false}
            end
          end

        _, _, _ ->
          {:error, :authorization_not_found}
      end)
    end

    field :authorize_many, non_null(list_of(non_null(:boolean))) do
      arg(:resource, non_null(:resource))
      arg(:ids, list_of(:id))
      arg(:relationship, non_null(:authorization_relationship))

      resolve(fn
        _,
        %{resource: :storyline, ids: ids, relationship: relationship},
        %{context: %{current_member: actor}} ->
          # call authorization functions here
          {:ok,
           Storylines.authorize_many(ids, relationship, actor)
           |> Enum.map(fn
             :ok -> true
             {:error, :unauthorized} -> false
           end)}

        _, _, _ ->
          {:error, :authorization_not_found}
      end)
    end
  end
end
