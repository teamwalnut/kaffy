defmodule ApiWeb.Utils.Error do
  @moduledoc """
  Helper module to make sure we're handling errors in a safe manner,
  this Struct makes sure we report errors to the end user in a structured way
  """
  require Logger
  alias __MODULE__

  defstruct [:code, :message, :status_code]

  # Error Tuples
  # ------------

  # Regular errors
  def normalize({:error, reason}) do
    handle(reason)
  end

  # Ecto transaction errors
  def normalize({:error, _operation, reason, _changes}) do
    handle(reason)
  end

  # Httpoison errors
  def normalize(%HTTPoison.Response{status_code: status_code, body: message}) do
    other = %{status_code: status_code, message: message}
    handle(other)
  end

  def normalize(%HTTPoison.Error{reason: reason}) do
    handle(reason)
  end

  # In case we want to return our own error
  def normalize(%__MODULE__{} = error) do
    error
  end

  # Unhandled errors
  def normalize(other) do
    handle(other)
  end

  defp flat_traverse_errors({_, nested_errors = %{}}) do
    Enum.map(nested_errors, &flat_traverse_errors/1)
  end

  defp flat_traverse_errors({k, v}) do
    %Error{
      code: :validation,
      message: String.capitalize("#{k} #{v}"),
      status_code: 422
    }
  end

  # Handle Different Errors
  # -----------------------

  defp handle(code) when is_atom(code) do
    {status, message} = metadata(code)

    %Error{
      code: code,
      message: message,
      status_code: status
    }
  end

  defp handle(errors) when is_list(errors) do
    Enum.map(errors, &handle/1)
  end

  defp handle(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {err, _opts} -> err end)
    |> Enum.map(&flat_traverse_errors/1)
    |> List.flatten()
  end

  defp handle(message) when is_binary(message) do
    %Error{
      code: :unknown,
      message: message,
      status_code: 500
    }
  end

  # ... Handle other error types here ...
  defp handle(other) do
    Logger.error("Unhandled error term:\n#{inspect(other)}")
    handle(:unknown)
  end

  # Build Error Metadata
  # --------------------

  defp metadata(:unknown_resource), do: {400, "Unknown Resource"}
  defp metadata(:invalid_argument), do: {400, "Invalid arguments passed"}
  defp metadata(:unauthenticated), do: {401, "You need to be logged in"}
  defp metadata(:password_hash_missing), do: {401, "Reset your password to login"}
  defp metadata(:incorrect_password), do: {401, "Invalid credentials"}

  defp metadata(:unauthorized) do
    Logger.warning("Tried to access protected resource without permissions")

    {403, "Unauthorized"}
  end

  defp metadata(:not_found), do: {404, "Resource not found"}
  defp metadata(:user_not_found), do: {404, "User not found"}
  defp metadata(:unknown), do: {500, "Something went wrong"}

  defp metadata(code) do
    Logger.warn("Unhandled error code: #{inspect(code)}")
    {422, to_string(code)}
  end
end
