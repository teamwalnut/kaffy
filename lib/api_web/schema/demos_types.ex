defmodule ApiWeb.Schema.DemoTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers
  alias Api.Storylines.Demos
  alias Api.Storylines.Demos.Archive
  alias Api.Storylines.Demos.DemoGate
  alias Api.Storylines.SmartObjects
  alias ApiWeb.Middlewares

  defp has_active_guides(demo_version, _args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(:storyline, :guides, demo_version)
    |> on_load(fn loader ->
      guides = loader |> Dataloader.get(:storyline, :guides, demo_version)

      loader
      |> Dataloader.load_many(:storyline, :annotations, guides)
      |> on_load(fn loader ->
        {:ok,
         Enum.reduce(guides, false, fn guide, acc ->
           if acc == false do
             length(loader |> Dataloader.get(:storyline, :annotations, guide)) > 0
           else
             true
           end
         end)}
      end)
    end)
  end

  defp screens_count(demo_version, _args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(:storyline, {:one, Api.Storylines.ScreenGrouping.FlowScreen},
      demo_version_screens_count: demo_version
    )
    |> on_load(fn loader ->
      result =
        loader
        |> Dataloader.get(:storyline, {:one, Api.Storylines.ScreenGrouping.FlowScreen},
          demo_version_screens_count: demo_version
        )

      {:ok, result}
    end)
  end

  @desc "Demo has several demo versions, only one is active"
  object :demo do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:last_played, :datetime)
    field(:is_shared, non_null(:boolean))
    field(:email_required, non_null(:boolean))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
    field(:archived_at, :datetime)
    field(:storyline, non_null(:storyline), resolve: dataloader(:storyline))
    field(:active_version, non_null(:demo_version), resolve: dataloader(:demo_version))
  end

  @desc "Demo Version is an instance of storyline"
  object :demo_version do
    field(:id, non_null(:id))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
    field(:created_by, non_null(:member), resolve: dataloader(:member))
    field(:start_screen, non_null(:screen), resolve: dataloader(:screen))
    field(:screens, list_of(non_null(:demo_screen)), resolve: dataloader(:screen))
    field(:flows, non_null(list_of(non_null(:flow))), resolve: dataloader(:flow))
    field(:guides, non_null(list_of(non_null(:guide))), resolve: dataloader(:guide))
    field(:patches, list_of(non_null(:patch)), resolve: dataloader(:patch))
    field(:settings, non_null(:demo_version_settings), resolve: dataloader(:settings))
    field(:screens_count, non_null(:integer), resolve: &screens_count/3)
    field(:has_active_guides, non_null(:boolean), resolve: &has_active_guides/3)
  end

  @desc """
  A screen is a snapshot of DOM stored on s3 (:s3_object_name) coupled with a screenshot and other
  metadata fields that describe the snapshot.
  """
  object :demo_screen do
    field(:id, non_null(:id))
    field(:screenshot_image_uri, non_null(:string))
    field(:last_edited, non_null(:datetime))
    field(:name, non_null(:string))
    field(:url, non_null(:string))
    field(:original_dimensions, :dimensions)
    field(:available_dimensions, non_null(list_of(non_null(:dimensions))))
    field(:s3_object_name, non_null(:string))
    field(:edits, non_null(list_of(non_null(:edit))), resolve: dataloader(:edit))

    field(:smart_object_instances, non_null(list_of(non_null(:smart_object_instance))),
      resolve: fn screen, _, _ ->
        instances =
          screen.smart_object_instances
          |> Enum.map(&SmartObjects.convert_edits(&1, :edits))
          |> Enum.map(&SmartObjects.convert_edits(&1, :edits_overrides))

        {:ok, instances}
      end
    )
  end

  object :demo_queries do
    field :demo, :demo do
      arg(:id, non_null(:id))

      resolve(fn _parent, %{id: id}, context ->
        case context do
          %{context: %{current_member: actor}} ->
            Demos.fetch_demo(id, actor)

          _ ->
            Demos.fetch_demo(id, nil)
        end
      end)
    end

    @desc """
    Lists all demos by user
    """
    field :demos, non_null(list_of(non_null(:demo))) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:is_archived, :boolean, default_value: false)

      resolve(fn _parent,
                 %{storyline_id: storyline_id, is_archived: is_archived},
                 %{context: %{current_member: actor}} ->
        if is_archived do
          Archive.list_demos(storyline_id, actor)
        else
          Demos.list_demos(storyline_id, actor)
        end
      end)
    end

    @desc """
    Lists storyline demos
    """
    field :all_demos, non_null(list_of(non_null(:demo))) do
      middleware(Middlewares.AuthnRequired)
      arg(:is_archived, :boolean, default_value: false)

      resolve(fn _parent,
                 %{is_archived: is_archived},
                 %{context: %{current_user: %{} = current_user}} ->
        member = Api.Companies.member_from_user(current_user.id)

        demos =
          case is_archived do
            true -> Archive.list_all_demos(member.company_id, member.id)
            false -> Demos.list_all_demos(member.company_id, member.id)
          end

        {:ok, demos}
      end)
    end

    @deprecated "Deprecated generate demo token as we moved to a different auth mechanism"
    @desc "Generates a demo access token"
    field :generate_demo_token, :string do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))

      resolve(fn _, %{storyline_id: _storyline_id}, %{context: %{current_user: _current_user}} ->
        {:ok, ""}
      end)
    end
  end

  input_object :variable_input do
    field(:id, non_null(:string))
    field(:name, non_null(:string))
    field(:value, non_null(:string))
  end

  object :demo_mutations do
    @desc "Create a demo from storyline"
    field :create_demo, non_null(:demo) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:name, non_null(:string))
      arg(:variables, list_of(:variable_input))

      resolve(fn _parent,
                 %{storyline_id: storyline_id, name: name} = attrs,
                 %{context: %{current_member: actor}} ->
        with {:ok, %{demo: created_demo}} <-
               Demos.create_demo(storyline_id, %{name: name}, actor, attrs[:variables] || []) do
          ApiWeb.Analytics.report_demo_created(actor.user, created_demo)
          {:ok, created_demo}
        end
      end)
    end

    @desc "Update a version for demo"
    field :update_demo_version, non_null(:demo) do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))
      arg(:demo_id, non_null(:id))
      arg(:variables, list_of(:variable_input))

      resolve(fn _parent,
                 %{storyline_id: storyline_id, demo_id: demo_id} = attrs,
                 %{context: %{current_member: actor}} ->
        with {:ok, %{demo: updated_demo}} <-
               Demos.create_new_demo_version(
                 storyline_id,
                 demo_id,
                 %{},
                 actor,
                 attrs[:variables] || []
               ) do
          ApiWeb.Analytics.report_demo_updated(actor.user, updated_demo)
          {:ok, updated_demo}
        end
      end)
    end

    @desc "Rename demo"
    field :rename_demo, non_null(:demo) do
      middleware(Middlewares.AuthnRequired)
      arg(:demo_id, non_null(:id))
      arg(:name, non_null(:string))

      resolve(fn _parent, %{demo_id: demo_id, name: name}, %{context: %{current_member: actor}} ->
        with {:ok, renamed_demo} <- Demos.rename_demo(demo_id, name, actor) do
          ApiWeb.Analytics.report_demo_renamed(actor.user, renamed_demo)
          {:ok, renamed_demo}
        end
      end)
    end

    @desc "Archive demo"
    field :archive_demo, non_null(:demo) do
      middleware(Middlewares.AuthnRequired)
      arg(:demo_id, non_null(:id))

      resolve(fn _parent, %{demo_id: demo_id}, %{context: %{current_member: actor}} ->
        Demos.get_demo!(demo_id)
        |> Archive.archive(actor)
      end)
    end

    @desc "Restore demo"
    field :restore_demo, non_null(:demo) do
      middleware(Middlewares.AuthnRequired)
      arg(:demo_id, non_null(:id))

      resolve(fn _parent, %{demo_id: demo_id}, %{context: %{current_member: actor}} ->
        Demos.get_demo!(demo_id) |> Archive.restore(actor)
      end)
    end

    @desc "Update demo is shared"
    field :update_demo_is_shared, non_null(:demo) do
      middleware(Middlewares.AuthnRequired)
      arg(:demo_id, non_null(:id))
      arg(:is_shared, non_null(:boolean))

      resolve(fn _parent,
                 %{demo_id: demo_id, is_shared: is_shared},
                 %{context: %{current_member: actor}} ->
        with {:ok, demo} <- Demos.update_is_shared(demo_id, is_shared, actor) do
          ApiWeb.Analytics.report_demo_sharing_updated(actor.user, demo)
          {:ok, demo}
        end
      end)
    end

    @desc "Update demo gate properties"
    field :update_demo_gate, non_null(:demo) do
      middleware(Middlewares.AuthnRequired)
      arg(:demo_id, non_null(:id))
      arg(:is_email_required, non_null(:boolean))

      resolve(fn _parent,
                 %{demo_id: demo_id, is_email_required: is_email_required},
                 %{context: %{current_member: actor}} ->
        demo = Demos.get_demo!(demo_id)

        if is_email_required do
          demo |> DemoGate.require_email(actor)
        else
          demo |> DemoGate.disable_email(actor)
        end
      end)
    end

    @desc "Update demo last played"
    field :update_demo_last_played, non_null(:demo) do
      arg(:demo_id, non_null(:id))

      resolve(fn _parent, %{demo_id: demo_id}, %{context: context} ->
        with {:ok, demo} <- Demos.update_last_played(demo_id) do
          current_user = Map.get(context, :current_user)
          ApiWeb.Analytics.report_demo_played(current_user, demo)
          {:ok, demo}
        end
      end)
    end
  end
end
