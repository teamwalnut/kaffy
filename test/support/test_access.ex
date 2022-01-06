defmodule Api.TestAccess do
  @moduledoc false
  alias Api.Companies.Member
  defstruct viewer: false, presenter: false, editor: false, company_admin: false
  defp assert_return(role, pass_authorization, result)

  defp assert_return(role, true, {:ok, %{errors: [%{code: :unauthorized}]}}) do
    raise ExUnit.AssertionError,
      message: "Expected to pass authorization for #{role}, but got unauthorized"
  end

  defp assert_return(role, true, {:error, :unauthorized}) do
    raise ExUnit.AssertionError,
      message: "Expected to pass authorization for #{role}, but got unauthorized"
  end

  defp assert_return(_role, true, {:ok, _}), do: nil
  defp assert_return(_role, false, {:error, :unauthorized}), do: nil
  defp assert_return(_role, false, {:ok, %{errors: [%{code: :unauthorized}]}}), do: nil

  defp assert_return(role, false, {:ok, %{errors: errors}}) when not is_nil(errors) do
    raise ExUnit.AssertionError,
      message:
        "Expected to fail authorization for #{role}, but got other errors #{inspect(errors)}"
  end

  defp assert_return(role, false, {:ok, %{data: data}}) when not is_nil(data) do
    raise ExUnit.AssertionError,
      message: "Expected to fail authorization for #{role}, but got {:ok, %{data: %{}}}"
  end

  defp assert_return(role, false, {:ok, _}) do
    raise ExUnit.AssertionError,
      message: "Expected to fail authorization for #{role}, but got {:ok, _}"
  end

  def assert_roles(fun, %Member{} = member, %__MODULE__{} = test_access) do
    for role <- [:viewer, :presenter, :editor, :company_admin] do
      assert_return(role, Map.get(test_access, role), fun.(%{member | role: role}))
    end
  end
end
