defmodule ApiWeb.Schema do
  @moduledoc false
  use Absinthe.Schema
  @schema_provider Absinthe.Schema.PersistentTerm
  alias ApiWeb.Middlewares.{ErrorHandler, SafeResolution}

  # note(itay): The order of import_types is important because this is run using a macro,
  # so it will actually run during compile-time and not run-time.
  import_types(Absinthe.Type.Custom)
  import_types(ApiWeb.Schema.AccountTypes)
  import_types(ApiWeb.Schema.FeaturesFlagsTypes)
  import_types(ApiWeb.Schema.PatchingTypes)
  import_types(ApiWeb.Schema.StorylineTypes)
  import_types(ApiWeb.Schema.CompanyTypes)
  import_types(ApiWeb.Schema.EditingTypes)
  import_types(ApiWeb.Schema.ScreenGroupingTypes)
  import_types(ApiWeb.Schema.AnnotationTypes)
  import_types(ApiWeb.Schema.DemoTypes)
  import_types(ApiWeb.Schema.SmartObjectsTypes)
  import_types(ApiWeb.Schema.EngagementTypes)
  import_types(ApiWeb.Schema.BusinessIntegrationTypes)
  import_types(ApiWeb.Schema.SettingsTypes)
  import_types(ApiWeb.Schema.ComplianceTypes)
  import_types(ApiWeb.Schema.AuthorizationTypes)
  import_types(ApiWeb.Schema.AsyncJobs.FindAndReplaceTypes)
  import_types(ApiWeb.Schema.DemoCustomizationsTypes)

  query do
    import_fields(:compliance_queries)
    import_fields(:engagement_queries)
    import_fields(:settings_queries)
    import_fields(:business_integration_queries)
    import_fields(:features_flag_queries)
    import_fields(:account_queries)
    import_fields(:company_queries)
    import_fields(:storyline_queries)
    import_fields(:demo_queries)
    import_fields(:authorization_queries)
    import_fields(:async_job_queries)
    import_fields(:demo_customizations_queries)
  end

  mutation do
    import_fields(:company_mutations)
    import_fields(:storyline_mutations)
    import_fields(:editing_mutations)
    import_fields(:flow_mutations)
    import_fields(:smart_objects_mutations)
    import_fields(:annotation_mutations)
    import_fields(:demo_mutations)
    import_fields(:patch_mutations)
    import_fields(:settings_mutations)
    import_fields(:compliance_mutations)
    import_fields(:async_job_mutations)
    import_fields(:demo_customizations_mutations)
    import_fields(:account_mutations)
  end

  # Dataloader stuff,
  def context(ctx) do
    Map.put(ctx, :loader, loader())
  end

  defp loader do
    Dataloader.new()
    |> Dataloader.add_source(:screen, Api.Dataloader.data(:screen))
    |> Dataloader.add_source(:storyline, Api.Dataloader.data(:storyline))
    |> Dataloader.add_source(:company, Api.Dataloader.data(:company))
    |> Dataloader.add_source(:member, Api.Dataloader.data(:member))
    |> Dataloader.add_source(:member_invite, Api.Dataloader.data(:member_invite))
    |> Dataloader.add_source(:user, Api.Dataloader.data(:user))
    |> Dataloader.add_source(:collaborator, Api.Dataloader.data(:collaborator))
    |> Dataloader.add_source(:edit, Api.Dataloader.data(:edit))
    |> Dataloader.add_source(:flow, Api.Dataloader.data(:flow))
    |> Dataloader.add_source(:patch, Api.Dataloader.data(:patch))
    |> Dataloader.add_source(:guide, Api.Dataloader.data(:guide))
    |> Dataloader.add_source(:annotation, Api.Dataloader.data(:annotation))
    |> Dataloader.add_source(:demo, Api.Dataloader.data(:demo))
    |> Dataloader.add_source(:settings, Api.Dataloader.data(:settings))
    |> Dataloader.add_source(:demo_version, Api.Dataloader.data(:demo_version))
    |> Dataloader.add_source(:smart_object_class, Api.Dataloader.data(:smart_object_class))
    |> Dataloader.add_source(:custom_domain, Api.Dataloader.data(:custom_domain))
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  def middleware(
        middleware,
        _field,
        %{identifier: type}
      )
      when type in [:query, :mutation] do
    SafeResolution.apply(middleware) ++ [ErrorHandler]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end
end
