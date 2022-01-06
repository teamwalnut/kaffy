defmodule Api.Kaffy.Companies.MemberAdmin do
  @moduledoc false

  alias Api.Companies.Member
  alias Api.Repo
  alias ApiWeb.FeaturesFlags.Provider.Launchdarkly

  def index(_) do
    [
      id: nil,
      role: nil,
      company: %{
        name: "Company",
        value: fn m ->
          m = m |> Api.Repo.preload(:company)
          m.company.name
        end
      },
      user: %{
        name: "User",
        value: fn m ->
          m = m |> Api.Repo.preload(:user)
          "#{m.user.first_name} #{m.user.last_name}"
        end
      },
      company_id: nil,
      user_id: nil,
      inserted_at: nil,
      updated_at: nil
    ]
  end

  def search_fields(_schema) do
    [
      :id,
      user: [:id, :first_name, :first_name],
      company: [:id, :name]
    ]
  end

  def insert(conn, _changeset) do
    params = conn.params["member"]
    company = Api.Companies.get_company!(params["company_id"])
    {:ok, member} = Api.Companies.add_member(params["user_id"], company)

    member =
      member
      |> Repo.preload(:user)

    :ok =
      member.user
      |> Launchdarkly.identify()

    {:ok, member}
  end

  def delete(conn, _changeset) do
    Api.Repo.get(Member, conn.params["id"])
    |> Api.Repo.delete()
  end

  def create_changeset(schema, attrs) do
    Member.create_changeset(schema, attrs)
  end

  def update_changeset(schema, attrs) do
    Member.update_changeset(schema, attrs)
  end

  def form_fields(_) do
    [
      role: %{
        choices: [
          {"Company Admin", "company_admin"},
          {"Editor", "editor"},
          {"Presenter", "presenter"},
          {"Viewer", "viewer"}
        ]
      },
      company_id: %{type: :string, label: "Company ID"},
      user_id: %{type: :string, label: "User ID"}
    ]
  end
end
