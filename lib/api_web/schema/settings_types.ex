defmodule ApiWeb.Schema.SettingsTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias Api.Companies
  alias Api.Repo
  alias Api.Settings.{AnnotationSettings, DemoVersionSettings, StorylineSettings}
  alias Api.Settings.Items.{DimStyle, Fab}
  alias ApiWeb.Middlewares

  require Logger
  import Absinthe.Resolution.Helpers

  enum :dim_style do
    values(DimStyle.kinds())
  end

  enum :fab_position do
    values(Ecto.Enum.values(Fab, :position))
  end

  enum :annotation_size do
    values(Ecto.Enum.values(AnnotationSettings, :size))
  end

  input_object :fab_settings_input do
    field(:enabled, :boolean)
    field(:position, :fab_position)
    field(:text, :string)
    field(:target_url, :string)
  end

  object :fab_settings do
    field(:enabled, non_null(:boolean))
    field(:position, :fab_position)
    field(:text, :string)
    field(:target_url, :string)
  end

  object :storyline_fab_settings do
    field(:enabled, :boolean)
    field(:position, :fab_position)
    field(:text, :string)
    field(:target_url, :string)
  end

  input_object :guides_settings_input do
    field(:show_glow, :boolean)
    field(:glow_color, :string)
    field(:background_color, :string)
    field(:font_color, :string)
    field(:font_size, :integer)
    field(:accent_color, :string)
    field(:smooth_scrolling, :boolean)
    field(:show_dismiss_button, :boolean)
    field(:show_back_button, :boolean)
    field(:show_main_button, :boolean)
    field(:main_button_text, :string)
    field(:dim_by_default, :boolean)
    field(:dim_style, :dim_style)
    field(:celebrate_guides_completion, :boolean)
    field(:show_avatar, :boolean)
    field(:avatar_url, :string)
    field(:avatar_title, :string)
    field(:fab, :fab_settings_input)
  end

  input_object :annotation_settings_input do
    field(:show_main_button, :boolean)
    field(:main_button_text, :string)
    field(:show_dismiss_button, :boolean)
    field(:show_back_button, :boolean)
    field(:show_avatar, :boolean)
    field(:avatar_url, :string)
    field(:avatar_title, :string)
    field(:show_dim, :boolean)
    field(:size, :annotation_size)
  end

  @desc "The settings for the guides"
  object :guides_settings do
    field(:show_glow, non_null(:boolean))
    field(:glow_color, non_null(:string))
    field(:background_color, non_null(:string))
    field(:font_color, non_null(:string))
    field(:font_size, non_null(:integer))
    field(:accent_color, non_null(:string))
    field(:smooth_scrolling, non_null(:boolean))

    field(:hide_dismiss, non_null(:boolean),
      deprecate:
        "The old way we used to know if to show/hide the dismiss button. We now use the :show_dismiss_button field instead."
    ) do
      resolve(fn guides_settings, _, _ ->
        {:ok, !guides_settings.show_dismiss_button}
      end)
    end

    field(:show_dismiss_button, non_null(:boolean))
    field(:show_back_button, non_null(:boolean))
    field(:show_main_button, non_null(:boolean))
    field(:main_button_text, non_null(:string))
    field(:dim_by_default, non_null(:boolean))
    field(:dim_style, non_null(:dim_style))
    field(:celebrate_guides_completion, non_null(:boolean))
    field(:show_avatar, non_null(:boolean))
    field(:avatar_url, :string)
    field(:avatar_title, :string)
    field(:fab, non_null(:fab_settings))
  end

  @desc "The uncascaded settings for the guides of storylines"
  object :storyline_guides_settings do
    field(:show_glow, :boolean)
    field(:glow_color, :string)
    field(:background_color, :string)
    field(:font_color, :string)
    field(:font_size, :integer)
    field(:accent_color, :string)
    field(:smooth_scrolling, :boolean)

    field(:hide_dismiss, :boolean,
      deprecate:
        "The old way we used to know if to show/hide the dismiss button. We now use the :show_dismiss_button field instead."
    ) do
      resolve(fn storyline_guides_settings, _, _ ->
        hide_dismiss =
          if storyline_guides_settings.show_dismiss_button == nil,
            do: nil,
            else: !storyline_guides_settings.show_dismiss_button

        {:ok, hide_dismiss}
      end)
    end

    field(:show_dismiss_button, :boolean)
    field(:show_back_button, :boolean)
    field(:show_main_button, :boolean)
    field(:main_button_text, :string)
    field(:dim_by_default, :boolean)
    field(:dim_style, :dim_style)
    field(:celebrate_guides_completion, :boolean)
    field(:show_avatar, :boolean)
    field(:avatar_url, :string)
    field(:avatar_title, :string)
    field(:fab, non_null(:storyline_fab_settings))
  end

  @desc "Default settings for the company"
  object :company_settings do
    field(:id, non_null(:id))
    field(:main_color, non_null(:string))
    field(:secondary_color, non_null(:string))
    field(:disable_loader, non_null(:boolean))
    field(:guides_settings, non_null(:guides_settings), resolve: dataloader(:settings))
  end

  @desc "The unified interface between cascaded storyline settings and demo settings"
  interface :settings do
    field(:id, non_null(:id))
    field(:global_js, :string)
    field(:global_css, :string)
    field(:main_color, non_null(:string))
    field(:secondary_color, non_null(:string))
    field(:disable_loader, non_null(:boolean))
    field(:guides_settings, non_null(:guides_settings))

    resolve_type(fn
      %StorylineSettings{}, _ -> :storyline_settings
      %DemoVersionSettings{}, _ -> :demo_version_settings
      _, _ -> nil
    end)
  end

  @desc "The cascaded settings of a storyline"
  object :cascaded_storyline_settings do
    field(:id, non_null(:id))
    field(:global_js, :string)
    field(:global_css, :string)
    field(:main_color, non_null(:string))
    field(:secondary_color, non_null(:string))
    field(:disable_loader, non_null(:boolean))
    field(:guides_settings, non_null(:guides_settings))

    interface(:settings)
  end

  @desc "The settings of a demo"
  object :demo_version_settings do
    field(:id, non_null(:id))
    field(:global_js, :string)
    field(:global_css, :string)
    field(:main_color, non_null(:string))
    field(:secondary_color, non_null(:string))
    field(:disable_loader, non_null(:boolean))
    field(:guides_settings, non_null(:guides_settings), resolve: dataloader(:settings))

    interface(:settings)
  end

  @desc "The uncascaded settings of a storyline"
  object :storyline_settings do
    field(:id, non_null(:id))
    field(:global_js, :string)
    field(:global_css, :string)
    field(:main_color, :string)
    field(:secondary_color, :string)
    field(:disable_loader, :boolean)

    field(:guides_settings, non_null(:storyline_guides_settings), resolve: dataloader(:settings))
  end

  @desc "The settings of an annotation"
  object :annotation_settings do
    field(:show_main_button, :boolean)
    field(:main_button_text, :string)
    field(:show_dismiss_button, :boolean)
    field(:show_back_button, :boolean)
    field(:show_avatar, :boolean)
    field(:avatar_url, :string)
    field(:avatar_title, :string)
    field(:show_dim, :boolean)
    field(:size, :annotation_size)
  end

  object :settings_queries do
    @desc "Get the uncascaded settings of a storyline"
    field :storyline_settings, :storyline_settings do
      middleware(Middlewares.AuthnRequired)
      arg(:storyline_id, non_null(:id))

      resolve(fn _parent, %{storyline_id: storyline_id}, _ ->
        Api.Settings.fetch_nullable_storyline_settings(storyline_id)
      end)
    end

    @desc "Get the default settings for the company"
    field :company_settings, :company_settings do
      middleware(Middlewares.AuthnRequired)

      resolve(fn _, _, %{context: %{current_user: current_user}} ->
        member = Companies.member_from_user(current_user.id) |> Repo.preload(:company)

        Api.Settings.fetch_company_settings(member.company_id)
      end)
    end
  end

  object :settings_mutations do
    @desc "Update settings of storyline"
    field :update_storyline_settings, non_null(:cascaded_storyline_settings) do
      middleware(Middlewares.AuthnRequired)

      arg(:storyline_id, non_null(:id))
      arg(:global_js, :string)
      arg(:global_css, :string)
      arg(:main_color, :string)
      arg(:secondary_color, :string)
      arg(:disable_loader, :boolean)
      arg(:guides_settings, :guides_settings_input)

      resolve(fn _parent,
                 %{storyline_id: storyline_id} = args,
                 %{context: %{current_member: actor}} ->
        case Api.Settings.update_storyline_settings(storyline_id, args, actor) do
          {:ok, _} ->
            cascaded_storyline_settings = storyline_id |> Api.Settings.get_storyline_settings()
            {:ok, cascaded_storyline_settings}

          other ->
            other
        end
      end)
    end

    field :update_company_settings, non_null(:company_settings) do
      middleware(Middlewares.AuthnRequired)

      arg(:main_color, :string)
      arg(:secondary_color, :string)
      arg(:disable_loader, :boolean)
      arg(:guides_settings, :guides_settings_input)

      resolve(fn _parent, args, %{context: %{current_member: actor}} ->
        Api.Settings.update_company_settings(args, actor)
      end)
    end
  end
end
