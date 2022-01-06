defmodule Api.Kaffy.Patching.PatchAdmin do
  @moduledoc false

  def index(_) do
    [
      id: nil,
      position: %{
        name: "Data Position",
        value: fn p ->
          p.data.position
        end
      },
      target: %{
        name: "Data Target URL Glob",
        value: fn p ->
          p.data.target_url_glob
        end
      },
      company: %{
        name: "Company",
        value: fn s ->
          s = s |> Api.Repo.preload(:company)
          if s.company, do: s.company.name, else: "none"
        end
      },
      company_id: nil,
      storyline_id: nil,
      inserted_at: nil,
      updated_at: nil,
      selector: %{
        name: "Data Selector",
        value: fn p ->
          p.data.css_selector
        end
      },
      html: %{
        name: "Data Html",
        value: fn p ->
          p.data.html
        end
      }
    ]
  end

  def search_fields(_schema) do
    [
      :storyline_id,
      :company_id,
      company: [:name]
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
