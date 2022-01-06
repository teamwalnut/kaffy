defmodule Api.Repo do
  use Ecto.Repo,
    otp_app: :api,
    adapter: Ecto.Adapters.Postgres

  @doc """
  A function that wraps the return value of `get` into a result type instead a nullable
  """
  def fetch(queryable, id, opts \\ []) do
    case get(queryable, id, opts) do
      nil -> {:error, :not_found}
      struct -> {:ok, struct}
    end
  end

  @doc """
  A function that wraps the return value of `get_by` into a result type instead a nullable
  """
  def fetch_by(queryable, clauses, opts \\ []) do
    case get_by(queryable, clauses, opts) do
      nil -> {:error, :not_found}
      struct -> {:ok, struct}
    end
  end
end
