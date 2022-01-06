defmodule ApiWeb.Schema.DemoCustomizationsTypes do
  @moduledoc false
  alias ApiWeb.Middlewares
  use Absinthe.Schema.Notation
  alias Api.Storylines.Demos.DemoCustomizations

  enum :kind do
    value(:text, description: "Text variable")
    value(:image, description: "Image variable")
  end

  @desc "Variables used to customize demo"
  object :variable do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:description, non_null(:string))
    field(:default_value, non_null(:string))
    field(:kind, non_null(:kind))
  end

  object :demo_customizations_queries do
    @desc """
    Lists variables of a storyline
    """
    field :variables, non_null(list_of(non_null(:variable))) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))

      resolve(fn _parent, %{storyline_id: storyline_id}, %{context: %{current_member: actor}} ->
        DemoCustomizations.list_variables(storyline_id, actor)
      end)
    end
  end

  object :demo_customizations_mutations do
    @desc "Create/update a variable from storyline"
    field :create_or_update_variable, non_null(:variable) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:name, non_null(:string))
      arg(:description, non_null(:string))
      arg(:kind, non_null(:kind))
      arg(:default_value, non_null(:string))

      resolve(fn _parent, args, %{context: %{current_member: actor}} ->
        DemoCustomizations.create_or_update_variable(
          args[:storyline_id],
          Map.take(args, [:name, :description, :default_value, :kind]),
          actor
        )
      end)
    end
  end
end
