defmodule Api.Kaffy.Storylines.StorylineAdmin do
  @moduledoc false

  use Phoenix.Controller, namespace: ApiWeb

  def index(_) do
    [
      name: nil,
      id: nil,
      demo_flags: nil,
      created_by: %{
        name: "Created by",
        value: fn s ->
          s = s |> Api.Repo.preload(owner: [:user])
          s.owner.user.first_name
        end
      },
      inserted_at: %{
        name: "Created at",
        value: fn s ->
          s.inserted_at
        end
      },
      screens: %{
        name: "Screens",
        value: fn s ->
          s = s |> Api.Repo.preload(:screens)
          s.screens |> Enum.count()
        end
      },
      company: %{
        name: "Company",
        value: fn s ->
          s = s |> Api.Repo.preload(:company)
          s.company.name
        end
      }
    ]
  end

  def search_fields(_schema) do
    [
      :id,
      :name,
      company: [:name]
    ]
  end

  def resource_actions(_conn) do
    [
      open: %{
        name: "Open",
        action: fn c, s ->
          redirect(c, external: "https://app.teamwalnut.com/storylines/#{s.id}")
        end
      }
    ]
  end

  def form_fields(_) do
    [
      name: nil
    ]
  end

  def insert(_conn, _changeset) do
    {:error, "can't insert"}
  end

  def delete(_conn, _changeset) do
    {:error, "can't delete"}
  end

  def create_changeset(_schema, _attrs) do
    {:error, "can't create"}
  end

  def update_changeset(_entry, _attrs) do
    {:error, "can't update currently"}
  end
end
