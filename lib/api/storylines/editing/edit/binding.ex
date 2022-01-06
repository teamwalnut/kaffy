defmodule Api.Storylines.Editing.Edit.Binding do
  @moduledoc false
  alias Api.Repo
  alias Api.Storylines.Editing
  alias Api.Storylines.Editing.Edit.WalnutVM
  alias Ecto.Multi
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Fragments do
    @moduledoc false
    defmacro program_embed_fn_name(props) do
      quote do
        fragment(
          "? -> 'program_embed' -> 'expression' ->> 'fn_name'",
          unquote(props)
        )
      end
    end
  end

  @primary_key false
  @derive {Jason.Encoder, only: [:original_text, :program_embed]}
  embedded_schema do
    field(:original_text, :string, default: "")
    embeds_one(:program_embed, WalnutVM, on_replace: :update)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:original_text])
    |> cast_embed_program(attrs)
    |> validate_required([:program_embed])
  end

  defp get_program_embed(attrs) do
    case Map.fetch(attrs, :program_embed) do
      {:ok, program_embed} ->
        {:ok, program_embed}

      :error ->
        # note(itay): The changeset comes with the program attribute as thats the name of the field
        # in the graphql layer, I support both with priority for program_embed, in case both are filled
        # we will ignore the attribute program
        case Map.fetch(attrs, :program) do
          {:ok, program} ->
            {:ok, program}

          :error ->
            # note(@benpony) support string key in favor of smart object edits
            # credo:disable-for-next-line
            case Map.fetch(attrs, "program_embed") do
              {:ok, program} ->
                {:ok, program}

              :error ->
                # credo:disable-for-next-line
                case Map.fetch(attrs, "program") do
                  {:ok, program} ->
                    {:ok, program}

                  :error ->
                    {:error,
                     "get_program_embed failed: key program_not_found not found in attrs Map"}
                end
            end
        end
    end
  end

  defp cast_program_embed(%WalnutVM{} = program_embed) do
    {:ok, program_embed}
  end

  defp cast_program_embed(program_embed) when is_binary(program_embed) do
    case Jason.decode(program_embed,
           # note(itay): We need to cleanup the @ as the JSON has every key starting with @
           keys: fn v -> String.replace(v, "@", "") |> Macro.underscore() |> String.to_atom() end
         ) do
      {:ok, program_embed} ->
        {:ok, program_embed}

      {:error, error} ->
        {:error, "Failed to JSON Decode program_embed: #{Jason.DecodeError.message(error)}"}
    end
  end

  defp cast_program_embed(program_embed) when is_map(program_embed) do
    # note(benpony): We need to recursively cleanup the @ as the Map has every key starting with @
    program_embed =
      program_embed
      |> keys_mapper(fn key ->
        key |> String.replace("@", "") |> Macro.underscore() |> String.to_atom()
      end)

    {:ok, program_embed}
  end

  defp keys_mapper(map, key_mapper_fn) when map |> is_map do
    map
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      cond do
        value |> is_map() ->
          acc
          |> Map.put(
            key_mapper_fn.(key),
            keys_mapper(value, key_mapper_fn)
          )

        value |> is_list() ->
          acc
          |> Map.put(
            key_mapper_fn.(key),
            value |> Enum.map(&keys_mapper(&1, key_mapper_fn))
          )

        true ->
          acc |> Map.put(key_mapper_fn.(key), value)
      end
    end)
  end

  defp cast_embed_program(changeset, attrs) do
    with {:ok, program_embed} <- get_program_embed(attrs),
         {:ok, result} <- cast_program_embed(program_embed) do
      Ecto.Changeset.put_embed(changeset, :program_embed, result)
    else
      {:error, reason} ->
        Ecto.Changeset.add_error(changeset, :program_embed, reason)
    end
  end

  def is_binding_edit_with_variables?(%__MODULE__{program_embed: program_embed}) do
    program_embed.expression.fn_name == "PUBLIC_FIELD"
  end

  def is_binding_edit_with_variables?(_), do: false

  def get_custom_variable_name(edit) do
    arg = WalnutVM.find_argument_name(edit.binding_edit_props.program_embed)
    arg.value
  end

  # Finds variable that matches with one of the arguments inside binding edit
  # variables:[{name: "Client Name", value: "Marina", id:"123456"}]
  # edit binding args:[{name: "name", value:"Client Name"}, {name: "defaultValue", value: "some default value"},
  # {name:"description", value:"some description"}]
  defp find_value_to_replace(variables, edit) do
    arg = WalnutVM.find_argument_name(edit.binding_edit_props.program_embed)

    if arg == nil do
      nil
    else
      # variable that it's name contains the value of the argument:
      # var = {name: "Client Name", value: "Marina", id:"123456"}
      # in the future we would want to do it by id (currently the id is different per each token)
      variable =
        variables
        |> Enum.find(fn variable ->
          variable.name |> String.downcase() == arg.value |> String.downcase()
        end)

      if variable == nil do
        nil
      else
        variable
      end
    end
  end

  defp update_edit_binding_with_value(value_to_replace, edit) do
    updated_args =
      WalnutVM.update_default_value(
        edit.binding_edit_props.program_embed.expression.args,
        value_to_replace
      )

    new_edit = put_in(edit.binding_edit_props.program_embed.expression.args, updated_args)

    new_edit =
      put_in(
        new_edit.binding_edit_props,
        new_edit.binding_edit_props |> Map.from_struct()
      )

    new_edit
  end

  @doc """
  Updates binding edits with variables list

  ## Examples

      iex> update_binding_edits_with_variables([{name: "Client Name", value: "Marina", id:"123456"}], [edit1, edit2])
      {:ok, %{{:update_binding_edit, id1} =>{...}, {{:update_binding_edit, id2}=>{...}}}
  """
  def update_binding_edits_with_variables(variables, edits) do
    edits
    |> Enum.filter(&is_binding_edit_with_variables?(&1.binding_edit_props))
    |> Enum.reduce(Multi.new(), fn edit, multi ->
      multi
      |> Multi.run({:update_binding_edit, edit.id}, fn _, _ ->
        value_to_replace_in_edit = find_value_to_replace(variables, edit)
        # credo:disable-for-next-line Credo.Check.Refactor.Nesting
        if value_to_replace_in_edit != nil do
          updated_edit =
            update_edit_binding_with_value(value_to_replace_in_edit.value, edit)
            |> Map.from_struct()

          Editing.update_edits(edit.screen_id, [updated_edit])
        else
          {:ok, edit}
        end
      end)
    end)
    |> Repo.transaction()
  end
end
