defmodule Api.EmbededSchema do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Api.SchemaValidations
      @primary_key false
    end
  end
end
