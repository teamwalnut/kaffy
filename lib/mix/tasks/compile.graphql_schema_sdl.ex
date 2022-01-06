defmodule Mix.Tasks.Compile.GraphqlSchemaSdl do
  use Mix.Task
  alias Mix.Tasks.Absinthe.Schema.Sdl

  @moduledoc """
  Compiles GraphQL schema SDL
  """

  def run(_args) do
    case Sdl.run([]) do
      true -> :ok
      _ -> :error
    end
  end
end
