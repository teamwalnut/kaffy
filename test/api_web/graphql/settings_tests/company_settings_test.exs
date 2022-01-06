defmodule ApiWeb.GraphQL.CompanySettings do
  use ApiWeb.GraphQLCase

  load_gql(
    ApiWeb.Schema,
    "test/support/queries/CompanySettings.gql"
  )

  setup [
    :register_and_log_in_user,
    :setup_company,
    :setup_member
  ]

  test "query company settings when they are not created", %{context: context} do
    query_gql(context: context) |> match_snapshot(scrub: ["id"])
  end

  test "query company settings when they are created", %{context: context, company: company} do
    company_settings_fixture(company)
    query_gql(context: context) |> match_snapshot(scrub: ["id"])
  end
end
