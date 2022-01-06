defmodule ApiWeb.Schema.StorylineTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Api.Companies
  alias Api.Storylines
  alias Api.Storylines.Archived
  alias Api.Storylines.SmartObjects
  alias ApiWeb.Middlewares

  defp screens_count(storyline, _args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(:storyline, {:one, Api.Storylines.Screen}, screens_count: storyline)
    |> on_load(fn loader ->
      result =
        loader
        |> Dataloader.get(:storyline, {:one, Api.Storylines.Screen}, screens_count: storyline)

      {:ok, result}
    end)
  end

  @desc "Storyline visibility, used for filtering"
  enum :storyline_visibility do
    value(:all, description: "All storylines, except archived")

    value(:private, description: "Private Storylines - e.g Storylines that were not set to public")

    value(:public,
      description:
        "Public Storylines - Public Storylines are accessible to everyone in your Company"
    )
  end

  object :demo_flags do
    @desc """
    Flag determining if we need to adjust the screen according to its original width/height.
    Only relevant when the system does responsiveness calculations in JS instead of CSS
    """
    field(:adjust_to_origin_dimensions, :boolean)
  end

  def get_many_storyline_settings(_, storylines) do
    Api.Settings.get_many_storyline_settings(storylines)
  end

  @desc "Storylines"
  object :storyline do
    field(:id, non_null(:id))
    field(:last_edited, non_null(:datetime))
    field(:inserted_at, non_null(:datetime))
    field(:is_public, non_null(:boolean))
    field(:is_shared, non_null(:boolean))
    field(:name, non_null(:string))
    field(:owner, non_null(:member), resolve: dataloader(:member))
    field(:screens_count, non_null(:integer), resolve: &screens_count/3)
    field(:start_screen, :screen, resolve: dataloader(:screen))

    field(:settings, non_null(:cascaded_storyline_settings),
      resolve: fn storyline, _, _ ->
        batch({__MODULE__, :get_many_storyline_settings}, storyline, fn batch_results ->
          {:ok, Map.get(batch_results, storyline.id)}
        end)
      end
    )

    field(:archived_at, :datetime)
    field(:demo_flags, :demo_flags)

    field(:collaborators, non_null(list_of(non_null(:collaborator))),
      resolve: dataloader(:collaborator)
    )

    field(:patches, list_of(non_null(:patch)), resolve: dataloader(:patch))

    field(:screens, list_of(non_null(:screen)), resolve: dataloader(:screen))

    field(:flows, non_null(list_of(non_null(:flow))), resolve: dataloader(:flow))
    field(:guides, non_null(list_of(non_null(:guide))), resolve: dataloader(:guide))
    field(:demos, list_of(non_null(:demo)), resolve: dataloader(:demo))

    @desc """
    Lists smart object classes
    """
    field(:smart_object_classes, non_null(list_of(non_null(:smart_object_class))),
      resolve: fn storyline, _, _ ->
        {:ok, classes} = SmartObjects.list_classes(storyline.id)
        res = classes |> Enum.map(&SmartObjects.convert_edits(&1, :edits))
        {:ok, res}
      end
    )
  end

  object :asset_manifest do
    field(:as_json, non_null(:string))
  end

  input_object :asset_manifest_input do
    field(:as_json, non_null(:string))
  end

  object :dimensions do
    field(:width, non_null(:integer))
    field(:height, non_null(:integer))
    field(:doc_height, :integer)
    field(:doc_width, :integer)
  end

  input_object :dimensions_input do
    field(:width, non_null(:integer))
    field(:height, non_null(:integer))
    field(:doc_height, :integer)
    field(:doc_width, :integer)
  end

  def unlinked_screen_ids_batch(nil, _) do
    MapSet.new([])
  end

  def unlinked_screen_ids_batch(storyline_id, _screen_ids) do
    Storylines.unlinked_screen_ids(storyline_id)
  end

  @desc """
  A screen is a snapshot of DOM stored on s3 (:s3_object_name) coupled with a screenshot and other
  metadata fields that describe the snapshot.
  """
  object :screen do
    field(:id, non_null(:id))
    field(:screenshot_image_uri, non_null(:string))
    field(:last_edited, non_null(:datetime))
    field(:name, non_null(:string))
    field(:url, non_null(:string))
    field(:original_dimensions, :dimensions)
    field(:available_dimensions, non_null(list_of(non_null(:dimensions))))
    field(:s3_object_name, non_null(:string))
    field(:storyline, non_null(:storyline), resolve: dataloader(:storyline))
    field(:edits, non_null(list_of(non_null(:edit))), resolve: dataloader(:edit))

    field(:is_unlinked, non_null(:boolean),
      resolve: fn screen, _, _ ->
        batch(
          {__MODULE__, :unlinked_screen_ids_batch, screen.storyline_id},
          screen.id,
          &{:ok, MapSet.member?(&1, screen.id)}
        )
      end
    )

    @desc """
    List smart object instances
    """
    field(:smart_object_instances, non_null(list_of(non_null(:smart_object_instance))),
      resolve: fn screen, _args, _ctx ->
        instances =
          screen.smart_object_instances
          |> Enum.map(&SmartObjects.convert_edits(&1, :edits))
          |> Enum.map(&SmartObjects.convert_edits(&1, :edits_overrides))

        {:ok, instances}
      end
    )
  end

  object :collaborator do
    field(:member, non_null(:member), resolve: dataloader(:member))
    field(:storyline, non_null(:storyline), resolve: dataloader(:storyline))
  end

  object :storyline_queries do
    @desc """
    Lists Storylines by visibility
    """
    field :storylines, non_null(list_of(non_null(:storyline))) do
      middleware(Middlewares.AuthnRequired)
      arg(:visibility, :storyline_visibility, default_value: :all)
      arg(:is_archived, :boolean, default_value: false)

      resolve(fn _parent,
                 %{visibility: visibility, is_archived: is_archived},
                 %{context: %{current_user: current_user}} ->
        member = Companies.member_from_user(current_user.id)

        storylines =
          case {is_archived, visibility} do
            {true, _} -> Archived.list(member.id, member.company_id)
            {_, :all} -> Storylines.list_all_storylines(member.id, member.company_id)
            {_, :private} -> Storylines.list_private_storylines(member.id, member.company_id)
            {_, :public} -> Storylines.list_public_storylines(member.company_id)
          end

        {:ok, storylines}
      end)
    end

    @desc """
    Gets a specific screen by storyline_id and screen_id
    """
    field :screen, :screen do
      arg(:storyline_id, non_null(:id))
      arg(:screen_id, non_null(:id))
      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent, %{screen_id: screen_id}, %{context: %{current_member: actor}} ->
        with {:ok, screen} <- Api.Storylines.fetch_screen(screen_id, actor) do
          # NOTE(@ostera): graphql still expects our manifest to just be a string,
          # so when we need it, we'll have to encode it with something like this:
          #
          #   screen = %{screen | asset_manifest: Jason.encode!(asset_manifest)}
          #
          # for the time being, we don't consume the manifest and we can drop it on
          # our way out
          screen = Map.delete(screen, :asset_manifest)
          {:ok, screen}
        end
      end)
    end

    @desc """
    Returns a single storyline by ID
    """
    field :storyline, :storyline do
      arg(:id, :id)
      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent, %{id: id}, %{context: %{current_member: actor}} ->
        Storylines.fetch(id, actor)
      end)
    end
  end

  object :storyline_mutations do
    @desc "Adds collaborator to a storyline"
    field :add_collaborator_to_storyline, non_null(:collaborator) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:member_id, non_null(:id))

      resolve(fn _parent,
                 %{storyline_id: storyline_id, member_id: member_id},
                 %{context: %{current_member: actor}} ->
        storyline_id
        |> Storylines.get_storyline!()
        |> Storylines.add_collaborator(member_id, actor)
      end)
    end

    @desc "Removes collaborator from a storyline"
    field :remove_collaborator_from_storyline, non_null(:boolean) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:member_id, non_null(:id))

      resolve(fn _parent,
                 %{storyline_id: storyline_id, member_id: member_id},
                 %{context: %{current_member: actor}} ->
        storyline_id
        |> Storylines.get_storyline!()
        |> Storylines.remove_collaborator(member_id, actor)
        |> case do
          :ok -> {:ok, true}
          other -> other
        end
      end)
    end

    @desc "Add screen to storyline"
    field :add_screen_to_storyline, :screen do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:screenshot_image_uri, non_null(:string))
      arg(:name, non_null(:string))
      arg(:url, non_null(:string))
      arg(:original_dimensions, :dimensions_input)
      arg(:available_dimensions, list_of(:dimensions_input))
      arg(:asset_manifest, :asset_manifest_input)
      arg(:s3_object_name, non_null(:string))

      resolve(fn _parent,
                 %{storyline_id: storyline_id} = args,
                 %{context: %{current_member: actor}} ->
        storyline = Storylines.get_storyline!(storyline_id)

        with {:ok, screen} <- Storylines.add_screen_to_default_flow(storyline, actor, args) do
          ApiWeb.Analytics.report_screen_added(actor.user, screen)
          {:ok, screen}
        end
      end)
    end

    @desc "updates the screen name"
    field :update_screen_name, non_null(:screen) do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))
      arg(:name, non_null(:string))

      resolve(fn _parent, %{id: id, name: name}, %{context: %{current_member: actor}} ->
        screen = Api.Storylines.get_screen!(id)

        with {:ok, screen} <- Api.Storylines.update_screen(screen, %{name: name}, actor) do
          ApiWeb.Analytics.report_screen_renamed(actor.user, screen)
          {:ok, screen}
        end
      end)
    end

    @desc "Deletes a screen"
    field :delete_screen, non_null(:screen) do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))

      resolve(fn _parent, %{id: id}, %{context: %{current_member: actor}} ->
        %Api.Storylines.Screen{} = screen = Api.Storylines.get_screen!(id)

        # We should probably add this: https://github.com/mirego/absinthe_error_payload instead
        with {:ok, %{screen: screen}} <- Api.ScreenDeletion.delete_screen(screen, actor) do
          ApiWeb.Analytics.report_screen_deleted(actor.user, screen)
          {:ok, screen}
        end
      end)
    end

    @desc "Delete screens"
    field :delete_screens, non_null(list_of(non_null(:screen))) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:screen_ids, non_null(list_of(non_null(:id))))

      resolve(fn _parent,
                 %{storyline_id: storyline_id, screen_ids: ids},
                 %{context: %{current_member: actor}} ->
        with storyline <- Api.Storylines.get_storyline!(storyline_id),
             {:ok, screens} <- Api.ScreenDeletion.delete_screens(storyline, ids, actor) do
          ApiWeb.Analytics.report_screens_deleted(actor.user, storyline_id, ids)
          {:ok, screens}
        end
      end)
    end

    @desc "Creates a new storyline"
    field :create_storyline, non_null(:storyline) do
      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent, %{context: %{current_member: actor}} ->
        with {:ok, storyline} <- Api.StorylineCreation.create_private_storyline(%{}, actor) do
          ApiWeb.Analytics.report_storyline_created(actor.user, storyline)
          {:ok, storyline}
        end
      end)
    end

    @desc "Sets a screen as start screen"
    field :update_storyline, non_null(:storyline) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:start_screen_id, :id)
      arg(:is_public, :boolean)
      arg(:is_shared, :boolean)
      arg(:name, :string)

      resolve(fn _parent,
                 %{storyline_id: storyline_id} = attrs,
                 %{context: %{current_member: actor}} ->
        %Api.Storylines.Storyline{} = storyline = Api.Storylines.get_storyline!(storyline_id)

        case Api.Storylines.update_storyline(storyline, attrs, actor) do
          {:ok, storyline} ->
            ApiWeb.Analytics.report_storyline_updated(actor.user, storyline)
            {:ok, storyline}

          err ->
            err
        end
      end)
    end

    @desc "Archives a storyline, removing all associated collaborators. Archived storylines can later on be restored"
    field :archive_storyline, non_null(:storyline) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))

      resolve(fn _, %{storyline_id: storyline_id}, %{context: %{current_member: actor}} ->
        storyline_id
        |> Api.Storylines.get_storyline!()
        |> Archived.archive(actor)
        |> case do
          {:ok, %{archived_storyline: storyline}} ->
            {:ok, storyline}

          err ->
            err
        end
      end)
    end

    @desc "Restores a storyline from the archive, this takes into account its previous visibility"
    field :restore_storyline, non_null(:storyline) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))

      resolve(fn _, %{storyline_id: storyline_id}, %{context: %{current_member: actor}} ->
        storyline_id
        |> Api.Storylines.get_storyline!()
        |> Archived.restore(actor)
      end)
    end

    @desc "Moves a screen to the new_position in the passed target_flow_id"
    field :move_screen, non_null(:screen) do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_id, non_null(:id))
      arg(:target_flow_id, non_null(:id))
      arg(:new_position, non_null(:integer))

      resolve(fn _,
                 %{
                   screen_id: screen_id,
                   target_flow_id: target_flow_id,
                   new_position: new_position
                 },
                 %{context: %{current_member: actor}} ->
        case Api.Storylines.move_screen(
               screen_id,
               target_flow_id,
               case new_position do
                 -1 -> :last
                 new_position -> new_position
               end,
               actor
             ) do
          {:ok, _flow_screens} ->
            screen = Api.Storylines.get_screen!(screen_id)
            {:ok, screen}

          err ->
            err
        end
      end)
    end

    @desc "Moves screens to the new position in the passed target_flow_id"
    field :move_screens, non_null(list_of(:screen)) do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_ids, non_null(list_of(:id)))
      arg(:target_flow_id, non_null(:id))
      arg(:new_position, non_null(:integer))

      resolve(fn _,
                 %{
                   screen_ids: screen_ids,
                   target_flow_id: target_flow_id,
                   new_position: new_position
                 },
                 %{context: %{current_member: actor}} ->
        case Api.Storylines.move_screens(
               screen_ids,
               target_flow_id,
               new_position,
               actor
             ) do
          {:ok, updated_screens} ->
            {:ok, updated_screens |> Enum.map(& &1.screen)}

          {:error, :invalid_position} ->
            {:error, :invalid_argument}

          err ->
            err
        end
      end)
    end

    @desc "Copies a storyline inside the same company while making it private and removing collaborators"
    field :copy_storyline, non_null(:storyline) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:target_owner_id, :id)

      resolve(fn
        _parent,
        %{storyline_id: storyline_id, target_owner_id: target_owner_id},
        %{context: %{current_member: actor}} ->
          storyline = Api.Storylines.get_storyline!(storyline_id)
          Api.Copying.copy_storyline(target_owner_id, storyline, actor)

        _parent, %{storyline_id: storyline_id}, %{context: %{current_member: actor}} ->
          storyline = Api.Storylines.get_storyline!(storyline_id)
          Api.Copying.copy_storyline(actor.id, storyline, actor)
      end)
    end

    @desc "Copies a screen to a given storyline"
    field :copy_screen, non_null(:screen) do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_id, non_null(:id))
      arg(:storyline_id, non_null(:id))

      resolve(fn _parent,
                 %{screen_id: screen_id, storyline_id: storyline_id},
                 %{context: %{current_member: actor}} ->
        screen = Api.Storylines.get_screen!(screen_id) |> Api.Repo.preload(:flow)

        Api.Storylines.copy_screen(
          screen,
          screen.flow,
          %{storyline_id: storyline_id, name: "Copy of #{screen.name}"},
          actor
        )
      end)
    end

    field :copy_screens, non_null(list_of(non_null(:screen))) do
      middleware(Middlewares.AuthnRequired)
      arg(:screen_ids, non_null(list_of(non_null(:id))))
      arg(:storyline_id, non_null(:id))

      resolve(fn _parent,
                 %{screen_ids: screen_ids, storyline_id: storyline_id},
                 %{context: %{current_member: actor}} ->
        Api.Storylines.copy_screens(
          screen_ids,
          %{
            storyline_id: storyline_id,
            prepend_name: "Copy of "
          },
          actor
        )
      end)
    end
  end
end
