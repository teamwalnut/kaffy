defmodule Mix.Tasks.LocalSetup do
  @moduledoc """
  Helps setting up the db models for local dev
  To run:
  ```
  mix local_setup --email [your email]
  ```
  """
  use Mix.Task
  alias Ecto.Multi

  @shortdoc "Bootstraps stuff needed for local env"
  def run(args) do
    {options, _, _} =
      OptionParser.parse(args,
        strict: [
          email: :string
        ]
      )

    :dev = Mix.env()
    Mix.Task.run("ecto.setup")
    Mix.Task.run("app.start")

    {:ok, _} =
      Multi.new()
      |> Multi.run(:company, fn _repo, _args ->
        Api.Companies.create_company(%{
          name: "Evil Corp Inc"
        })
      end)
      |> Multi.run(:user, fn _repo, _args ->
        Api.Accounts.register_user(%{
          first_name: "Demo",
          last_name: "God Jr.",
          email: options[:email],
          password: "1234567891011"
        })
      end)
      |> Multi.run("make_admin", fn _repo, %{user: user} ->
        Api.Accounts.make_admin!(user)
        {:ok, true}
      end)
      |> Multi.run(:member, fn _repo, %{company: company, user: user} ->
        Api.Companies.add_member(user.id, company)
      end)
      |> Multi.run(:domain, fn _repo, %{company: company} ->
        company.id
        |> Api.CustomDomains.create_custom_domain(%{
          domain: "evil.corp",
          env: "test"
        })
      end)
      |> Multi.run(:note, fn _repo, %{company: company, user: user} ->
        Mix.shell().info("""
            Added "#{user.email}" to "#{company.name}" as a Member
        """)

        {:ok, ""}
      end)
      |> Api.Repo.transaction()
  end
end
