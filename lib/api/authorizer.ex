defmodule Api.Authorizer do
  @moduledoc """
  This is the module that provides authorization functions for resources
  that adopt the AccessPolicy protocol
  """
  alias Api.Repo

  def authorize(struct, actor, relationship) do
    struct
    |> Repo.preload(AccessPolicy.preloads(struct))
    |> AccessPolicy.authorize(actor, relationship)
  end

  def authorize_many(list_of_struct, actor, relationship) do
    module =
      case list_of_struct |> Enum.map(fn %{__struct__: module} -> module end) |> Enum.uniq() do
        [module] -> module
        _ -> raise "Can only use authorize_many with a homogenous list of structs"
      end

    preloads = AccessPolicy.preloads(struct(module))

    list_of_struct
    |> Repo.preload(preloads)
    |> Enum.map(&AccessPolicy.authorize(&1, actor, relationship))
  end
end
