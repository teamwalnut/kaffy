defmodule Api.Storylines.Demos.DemoCustomizations do
  @moduledoc """
  Customizations to a Demo via Variables
  """
  alias Api.Repo
  alias Api.Storylines.Demos.Variable
  alias Api.Storylines.Editing.Edit

  @doc """
  Creates or updates a Variable

  ## Examples

      iex> create_or_update_variable("storyline_id", %{}, actor)
      {:ok, %Variable{}}

      iex> create_or_update_variable("storyline_id", %{}, actor)
      {:error, :unauthorized}
  """
  def create_or_update_variable(storyline_id, attrs, actor) do
    storyline = Api.Storylines.get_storyline!(storyline_id)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :editor) do
      variable =
        case Repo.get_by(Variable, storyline_id: storyline_id, name: attrs[:name]) do
          nil -> %Variable{storyline_id: storyline_id}
          var -> var
        end

      variable
      |> Variable.changeset(attrs)
      |> Repo.insert_or_update()
    end
  end

  @doc """
  Lists Variables

  ## Examples

      iex> list_variables("storyline_id", actor)
      {:ok, %Variable{}}

      iex> list_variables("storyline_id", actor)
      {:error, :unauthorized}
  """
  def list_variables(storyline_id, actor) do
    storyline = Api.Storylines.get_storyline!(storyline_id) |> Repo.preload(:variables)

    with :ok <- Api.Authorizer.authorize(storyline, actor, :presenter) do
      existing_variables_in_edits =
        Edit.bindings_variables_by_storyline_id_query(storyline_id)
        |> Repo.all()
        |> Enum.group_by(fn edit -> Edit.Binding.get_custom_variable_name(edit) end, fn x -> x end)
        |> Map.keys()

      variables =
        storyline.variables
        |> Enum.filter(fn var ->
          Enum.find(existing_variables_in_edits, fn var_name -> var_name == var.name end)
        end)

      {:ok, variables}
    end
  end
end
