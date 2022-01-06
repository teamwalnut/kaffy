defmodule ApiWeb.Schema.ComplianceTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias Api.Accounts
  alias ApiWeb.Middlewares

  object :compliance do
    field(:is_tac_approved, non_null(:boolean))
  end

  object :compliance_queries do
    @desc """
    Get compliance object that holds the user approval of our Terms and conditions and privacy policy
    """
    field :compliance, non_null(:compliance) do
      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent, _, %{context: %{current_user: current_user}} ->
        {:ok, %{is_tac_approved: current_user |> Accounts.approved_tac?()}}
      end)
    end
  end

  object :compliance_mutations do
    @desc "Update user's compliance"
    field :approve_tac, non_null(:compliance) do
      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent, _, %{context: %{current_user: current_user}} ->
        current_user |> Accounts.approve_tac()

        {:ok, %{is_tac_approved: current_user |> Accounts.approved_tac?()}}
      end)
    end
  end
end
