defmodule Api.Storylines.Editing.Edit.WalnutVM do
  # note(itay): Would mirror the frontend docs for WalnutVM but we have none
  use Ecto.Schema
  @primary_key false

  defmodule JSONEncoder do
    @moduledoc false
    def encode(value, opts, keys) do
      Map.take(value, keys)
      |> Map.to_list()
      |> Enum.map(fn {k, v} ->
        {
          Macro.camelize("@#{k}"),
          v
        }
      end)
      |> Jason.Encode.keyword(opts)
    end
  end

  defmodule Argument do
    @moduledoc false
    use Ecto.Schema
    @primary_key false

    embedded_schema do
      field(:name, :string)
      field(:value, :string)
    end

    defimpl Jason.Encoder, for: __MODULE__ do
      def encode(value, opts) do
        JSONEncoder.encode(value, opts, [:name, :value])
      end
    end
  end

  defmodule Expression do
    @moduledoc false
    use Ecto.Schema

    @primary_key false

    embedded_schema do
      field(:id, :string)
      field(:type, :string)
      field(:fn_name, :string)
      embeds_many(:args, Argument)
    end

    defimpl Jason.Encoder, for: __MODULE__ do
      def encode(value, opts) do
        JSONEncoder.encode(value, opts, [:id, :type, :fn_name, :args])
      end
    end
  end

  embedded_schema do
    field(:ast_version, :string)
    field(:env_version, :string)
    embeds_one(:expression, Expression)
  end

  # argument that contains the name of the variable:  {name: "name", value:"Client Name"}
  # "name" argument is used in FE to store variable name
  # arg = {name: "name", value:"Client Name"}
  def find_argument_name(program) do
    program.expression.args
    |> Enum.find(fn arg -> arg.name == "name" end)
  end

  def update_default_value(args, value_to_replace) do
    args
    |> Enum.map(fn arg ->
      # defaultValue is the name of the argument that in FE is used when rendering value of the token
      # here we want to update it with input that was recieved from the user in create demo wizard
      if arg.name == "defaultValue" do
        %{arg | value: value_to_replace}
      else
        arg
      end
    end)
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      JSONEncoder.encode(value, opts, [:ast_version, :env_version, :expression])
    end
  end
end
