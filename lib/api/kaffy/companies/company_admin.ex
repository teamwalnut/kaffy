defmodule Api.Kaffy.Companies.CompanyAdmin do
  @moduledoc false

  alias Api.Companies.Company

  def form_fields(_) do
    [
      name: %{create: :editable, update: :readonly},
      is_paying: %{type: :boolean, label: "Is Paying?"},
      is_locked: %{type: :boolean, label: "Is Locked?"}
    ]
  end

  def search_fields(_schema) do
    [
      :id,
      :name
    ]
  end

  def insert(conn, _changeset) do
    params = conn.params["company"]
    Api.Companies.create_company(params)
  end

  def delete(conn, _changeset) do
    Api.Companies.get_company!(conn.params["id"]) |> Api.Repo.delete()
  end

  def create_changeset(schema, attrs) do
    Company.create_changeset(schema, attrs)
  end

  def update_changeset(%Api.Companies.Company{} = company, attrs) do
    changeset = Company.update_changeset(company, attrs)

    if changeset.changes[:is_locked] == true && changeset.valid? == true do
      for member <- Api.Companies.list_members(company),
          user = Api.Accounts.get_user!(member.user_id) do
        Api.Accounts.delete_all_tokens(user)
      end
    end

    changeset
  end
end
