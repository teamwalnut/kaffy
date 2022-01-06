defmodule ApiWeb.Schema.PatchingTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias ApiWeb.Middlewares

  enum :html_patch_position do
    values(Ecto.Enum.values(Api.Patching.HtmlPatch, :position))
  end

  object :html_patch do
    field(:position, non_null(:html_patch_position))
    field(:css_selector, non_null(:string))
    field(:html, non_null(:string))
    field(:target_url_glob, :string)
  end

  input_object :html_patch_input_object do
    field(:position, non_null(:html_patch_position))
    field(:css_selector, non_null(:string))
    field(:html, non_null(:string))
    field(:target_url_glob, :string)
  end

  union :patch_data do
    # Note(Danni): Tried to do some macro magic to avoid this repetition,
    # couldnt make it work.. will continue off branch
    types([:html_patch])

    resolve_type(fn
      %Api.Patching.HtmlPatch{}, _ -> :html_patch
    end)
  end

  @desc """
  This is the wrapper object, only use this for low-level operations, we might remove it later on
  """
  object :patch do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:data, non_null(:patch_data))
  end

  object :patch_mutations do
    @desc "Adds html patch to a storyline"
    field :add_html_patch_to_storyline, non_null(:patch) do
      middleware(Middlewares.AuthnRequired)

      arg(:storyline_id, non_null(:id))
      arg(:name, non_null(:string))
      arg(:html_patch, non_null(:html_patch_input_object))

      resolve(fn _parent,
                 %{name: name, storyline_id: storyline_id, html_patch: html_patch},
                 %{context: %{current_member: actor}} ->
        html_patch = parse_html_patch_data(html_patch)

        Api.Patching.add_storyline_patch(storyline_id, html_patch, name, actor)
      end)
    end

    @desc "Adds a patch to a company"
    field :add_html_patch_to_company, non_null(:patch) do
      middleware(Middlewares.AuthnRequired)

      arg(:company_id, non_null(:id))
      arg(:name, non_null(:string))
      arg(:html_patch, non_null(:html_patch_input_object))

      resolve(fn _parent,
                 %{company_id: company_id, html_patch: html_patch, name: name},
                 %{context: %{current_member: actor}} ->
        html_patch = parse_html_patch_data(html_patch)

        Api.Patching.add_company_patch(company_id, html_patch, name, actor)
      end)
    end

    @desc "Updates a patch"
    field :update_html_patch, non_null(:patch) do
      middleware(Middlewares.AuthnRequired)

      arg(:patch_id, non_null(:id))
      arg(:html_patch_data, non_null(:html_patch_input_object))

      resolve(fn _parent,
                 %{patch_id: patch_id, html_patch_data: html_patch_data},
                 %{context: %{current_member: actor}} ->
        patch = Api.Patching.get_patch!(patch_id)

        Api.Patching.update_patch(patch, html_patch_data, actor)
      end)
    end

    @desc "Remove a patch"
    field :remove_patch, non_null(:patch) do
      middleware(Middlewares.AuthnRequired)

      arg(:patch_id, non_null(:id))

      resolve(fn _parent, %{patch_id: patch_id}, %{context: %{current_member: actor}} ->
        patch = Api.Patching.get_patch!(patch_id)

        Api.Patching.remove_patch(patch, actor)
      end)
    end
  end

  defp parse_html_patch_data(html_patch) do
    %Api.Patching.HtmlPatch{
      position: html_patch.position,
      css_selector: html_patch.css_selector,
      html: html_patch.html,
      target_url_glob: html_patch.target_url_glob
    }
  end
end
