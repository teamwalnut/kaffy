defmodule ApiWeb.Schema.SmartObjectsTypes do
  @moduledoc false
  require Logger
  use Absinthe.Schema.Notation

  alias Api.Storylines.SmartObjects
  alias ApiWeb.{GraphQLHelpers, Middlewares}

  import_types(ApiWeb.Schema.DOMTypes)

  object :smart_object_class do
    field(:id, non_null(:id))
    field(:storyline_id, non_null(:id))
    field(:name, non_null(:string))
    field(:thumbnail, :string)
    field(:edits, non_null(list_of(non_null(:edit))))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  input_object :new_smart_object_class do
    field(:name, non_null(:string))
    field(:thumbnail, non_null(:string))
    field(:edits, non_null(list_of(non_null(:new_edit))))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector_input)
  end

  object :smart_object_instance do
    field(:id, non_null(:id))
    field(:class_id, non_null(:id))
    field(:screen_id, non_null(:id))
    field(:storyline_id, non_null(:id))
    field(:edits, non_null(list_of(non_null(:edit))))
    field(:edits_overrides, non_null(list_of(non_null(:edit))))
    field(:detached, non_null(:boolean))
    field(:css_selector, non_null(:string))
    field(:frame_selectors, list_of(non_null(:string)))
    field(:dom_selector, :dom_selector)
  end

  input_object :new_smart_object_instance do
    field(:class_id, non_null(:id))
    field(:edits_overrides, list_of(non_null(:new_edit)))
    field(:override_css_selector, :string)
    field(:override_frame_selectors, list_of(non_null(:string)))
    field(:override_dom_selector, :dom_selector_input)
  end

  object :smart_objects_mutations do
    @desc "Adds new Smart Object class"
    field :add_smart_object_class, non_null(:smart_object_class) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:smart_object_class, non_null(:new_smart_object_class))

      resolve(fn
        _parent,
        %{storyline_id: storyline_id, smart_object_class: smart_object_class},
        %{context: %{current_member: actor}} ->
          new_smart_object_class =
            struct(
              %SmartObjects.Class{},
              Map.merge(smart_object_class, %{
                storyline_id: storyline_id,
                edits:
                  smart_object_class.edits
                  |> GraphQLHelpers.translate_mutation_polymorphism_of_edits()
                  |> Enum.map(&SmartObjects.convert_to_edit(&1))
              })
            )

          SmartObjects.create_class(new_smart_object_class, actor)
      end)
    end

    @desc "Update Smart Object class"
    field :update_smart_object_class, non_null(:smart_object_class) do
      middleware(Middlewares.AuthnRequired)
      arg(:smart_object_class_id, non_null(:id))
      arg(:name, :string)
      arg(:thumbnail, :string)
      arg(:edits, list_of(non_null(:new_edit)))

      resolve(fn _parent, args, %{context: %{current_member: actor}} ->
        %{smart_object_class_id: smart_object_class_id, edits: edits} = args

        class = SmartObjects.get_class!(smart_object_class_id)

        args = %{
          args
          | edits:
              edits
              |> GraphQLHelpers.translate_mutation_polymorphism_of_edits()
              |> Enum.map(&SmartObjects.convert_to_edit(&1))
        }

        SmartObjects.update_class_and_its_instances(class, args, actor)
      end)
    end

    @desc "Archive Smart Object class"
    field :archive_smart_object_class, non_null(:smart_object_class) do
      middleware(Middlewares.AuthnRequired)
      arg(:smart_object_class_id, non_null(:id))

      resolve(fn _parent,
                 %{smart_object_class_id: class_id},
                 %{context: %{current_member: actor}} ->
        SmartObjects.archive_class(class_id, actor)
      end)
    end

    @desc "Rename Smart Object class"
    field :rename_smart_object_class, non_null(:smart_object_class) do
      middleware(Middlewares.AuthnRequired)
      arg(:smart_object_class_id, non_null(:id))
      arg(:name, non_null(:string))

      resolve(fn _parent,
                 %{smart_object_class_id: class_id, name: name},
                 %{context: %{current_member: actor}} ->
        SmartObjects.rename_class(class_id, name, actor)
      end)
    end

    @desc "Detach a Smart Object Instance"
    field :detach_smart_object_instance, non_null(list_of(non_null(:smart_object_instance))) do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_id, non_null(:id))
      arg(:instance_id, non_null(:id))

      resolve(fn _parent,
                 %{screen_id: screen_id, instance_id: instance_id},
                 %{context: %{current_member: actor}} ->
        SmartObjects.detach_instance(screen_id, instance_id, actor)
      end)
    end

    @desc "Updates the set of Smart Object instances in a screen"
    field :update_smart_object_instances_in_screen,
          non_null(list_of(non_null(:smart_object_instance))) do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_id, non_null(:id))
      arg(:instances, non_null(list_of(non_null(:new_smart_object_instance))))

      resolve(fn _parent,
                 %{screen_id: screen_id, instances: instances},
                 %{context: %{current_member: actor}} ->
        # NOTE(@ostera): this is strictly a conversion between input arguments to Domain API calls
        instances =
          instances
          |> Enum.map(fn instance ->
            case Map.has_key?(instance, :edits_overrides) do
              true ->
                %{
                  instance
                  | edits_overrides:
                      instance.edits_overrides
                      |> GraphQLHelpers.translate_mutation_polymorphism_of_edits()
                }

              false ->
                instance
            end
          end)

        SmartObjects.update_instances_in_screen(screen_id, instances, actor)
      end)
    end
  end
end
