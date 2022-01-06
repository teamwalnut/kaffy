defmodule Api.Storylines.Demos.DemoGate do
  @moduledoc """
  Represents a demo gate. Gate which will be displayed when opening demo.
  Will prompt for email, password and etc.
  """
  alias Api.Repo
  alias Api.Storylines.Demos.Demo

  @doc """
  Require email identification on demo load

  ## Examples

      iex> require_email(demo, actor)
      {:ok, %Demo{}}

      iex> require_email(demo, bad_actor)
      {:error, :unauthorized}
  """
  def require_email(%Demo{} = demo, actor) do
    demo = demo |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(demo.storyline, actor, :presenter) do
      demo
      |> Demo.update_changeset(%{email_required: true})
      |> Repo.update()
    end
  end

  @doc """
  Disbale email identification on demo load
  ## Examples
      iex> disable_email(demo)
      {:ok, %Demo{}}
  """
  def disable_email(%Demo{} = demo, actor) do
    demo = demo |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(demo.storyline, actor, :presenter) do
      demo
      |> Demo.update_changeset(%{email_required: false})
      |> Repo.update()
    end
  end
end
