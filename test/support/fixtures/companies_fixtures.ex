defmodule Api.CompaniesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Companies` context.
  """
  alias Api.Settings.CompanySettings
  alias Api.Settings.GuidesSettings

  def unique_company_name, do: "company_#{System.unique_integer()}"
  def unique_domain, do: "#{Api.FixtureSequence.next("domain_")}.com"

  def company_fixture(attrs \\ %{}) do
    {:ok, company} =
      attrs
      |> Enum.into(%{name: unique_company_name()})
      |> Api.Companies.create_company()

    company
  end

  def company_settings_fixture(company) do
    %CompanySettings{
      main_color: "#FFFFFF",
      secondary_color: "#CCCCCC",
      disable_loader: true,
      company: company,
      guides_settings: %GuidesSettings{
        GuidesSettings.defaults()
        | glow_color: "#DDDDDD",
          background_color: "#EEEEEE",
          font_color: "#FF0000",
          font_size: 18,
          accent_color: "#00FFFF",
          smooth_scrolling: false,
          show_dismiss_button: true,
          dim_by_default: true
      }
    }
    |> Api.Repo.insert!()
  end

  def setup_company(attrs \\ %{}) do
    {:ok, company: company_fixture(attrs)}
  end

  def setup_member(%{user: user, company: company}) do
    do_setup_member(user, company)
  end

  defp do_setup_member(user, company) do
    {:ok, member} = Api.Companies.add_member(user.id, company, %{role: :company_admin})
    {:ok, member: member}
  end

  def company_and_member_fixture(%Api.Accounts.User{} = user, attrs \\ %{}) do
    company = company_fixture(attrs)
    {:ok, member} = Api.Companies.add_member(user.id, company, attrs)
    %{company: company, member: member}
  end
end
