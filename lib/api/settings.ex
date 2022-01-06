defmodule Api.Settings do
  @moduledoc """
  The Settings module that manages all application settings. Currently the available settings are:

  - `Api.Settings.CompanySettings`: company default settings
  - `Api.Settings.StorylineSettings`: settings for a storyline
  - `Api.Settings.DemoVersionSettings`: settings for a demo (pre-cascaded and not nullable)
  - `Api.Settings.GuidesSettings`: settings for guides as part of demo or in the company settings
    this means that these settings are not nullable (except for ["avatar_url", "avatar_title"] which can be null)
  - `Api.Settings.StorylineGuidesSettings`: settings for guides as part of a storyline, these
    settings can be null in order to be cascaded from `Api.Settings.CompanySettings` /
    `Api.Settings.GuidesSettings`
  """

  alias Api.Repo

  alias Api.Settings.{
    CompanySettings,
    DemoVersionSettings,
    GuidesSettings,
    StorylineGuidesSettings,
    StorylineSettings
  }

  alias Api.Storylines
  alias Api.Storylines.Demos
  alias Api.Storylines.Demos.Demo
  alias Api.Storylines.Storyline

  @doc """
  Updates the company settings

  ## Examples

      iex> update_company_settings(%{main_color: "#6E1DF4"}, actor)
      {:ok, %CompanySettings{}}

      iex> update_company_settings(%{main_color: "#6E1DF4"}, bad_actor)
      {:ok, :unauthorized}

      iex> update_company_settings(invalid_attrs, actor)
      {:error, %Changeset{}}

  ## Note (Jaap):
  We pass in the member here because it has a reference to the company_id, and we need the
  member later when we will do authorization, so this API is future proof
  """
  def update_company_settings(attrs, actor) do
    with :ok <- Api.Authorizer.authorize(actor.company, actor, :admin) do
      case fetch_company_settings(actor.company_id) do
        {:ok, settings} ->
          settings = Repo.preload(settings, :guides_settings)
          CompanySettings.update_changeset(settings, attrs)

        {:error, :not_found} ->
          CompanySettings.create_changeset(
            %CompanySettings{
              guides_settings: GuidesSettings.defaults(),
              company_id: actor.company_id
            },
            %{}
          )
      end
      |> Repo.insert_or_update()
    end
  end

  @doc """
  Fetches the company settings

  ## Examples

      iex> fetch_company_settings("id")
      {:ok, %CompanySettings{}}

      iex> fetch_company_settings("non_existent_id")
      {:error, :not_found}
  """
  def fetch_company_settings(company_id) do
    case Repo.fetch_by(CompanySettings, company_id: company_id) do
      {:ok, settings} ->
        {:ok, settings}

      {:error, :not_found} ->
        CompanySettings.create_changeset(
          %CompanySettings{CompanySettings.defaults() | company_id: company_id},
          %{}
        )
        |> Repo.insert()
    end
  end

  @doc """
  Copies the settings from origin_storyline_id to the passed target

  ## Examples

      iex> copy_storyline_settings(origin_storyline_id, %Api.Storylines.Demos.DemoVersion{})
      {:ok, %StorylineSettings{}}

      iex> copy_storyline_settings(origin_storyline_id, %Api.Storylines.Storyline{})
      {:ok, %StorylineSettings{}}

      iex> copy_storyline_settings(origin_storyline_id, %Api.Storylines.Demos.DemoVersion{})
      {:error, %Ecto.Changeset{}}

      iex> copy_storyline_settings(origin_storyline_id, %Api.Storylines.Storyline{})
      {:error, %Ecto.Changeset{}}

  """
  def copy_storyline_settings(origin_storyline_id, %Storyline{id: storyline_id}) do
    {:ok, origin_settings} = fetch_nullable_storyline_settings(origin_storyline_id)
    origin_settings = Repo.preload(origin_settings, :guides_settings)

    guides_settings_map =
      Map.from_struct(origin_settings.guides_settings)
      |> Map.drop([:id])
      |> Map.put(:fab, Map.from_struct(origin_settings.guides_settings.fab))

    copied_settings_attrs = %{
      global_js: origin_settings.global_js,
      global_css: origin_settings.global_css,
      main_color: origin_settings.main_color,
      secondary_color: origin_settings.secondary_color,
      disable_loader: origin_settings.disable_loader,
      guides_settings: guides_settings_map,
      storyline_id: storyline_id
    }

    %StorylineSettings{}
    |> StorylineSettings.create_changeset(copied_settings_attrs)
    |> Repo.insert()
  end

  def copy_storyline_settings(origin_storyline_id, %Demo{id: demo_id}) do
    case get_storyline_settings(origin_storyline_id) do
      nil ->
        {:error, :not_found}

      storyline_settings ->
        demo_version = Demos.get_active_demo_version!(demo_id)
        guides_settings = storyline_settings.guides_settings

        demo_version_settings =
          %DemoVersionSettings{
            global_js: storyline_settings.global_js,
            global_css: storyline_settings.global_css,
            main_color: storyline_settings.main_color,
            secondary_color: storyline_settings.secondary_color,
            disable_loader: storyline_settings.disable_loader,
            demo_version_id: demo_version.id,
            guides_settings: %GuidesSettings{
              show_glow: guides_settings.show_glow,
              glow_color: guides_settings.glow_color,
              background_color: guides_settings.background_color,
              font_color: guides_settings.font_color,
              font_size: guides_settings.font_size,
              accent_color: guides_settings.accent_color,
              smooth_scrolling: guides_settings.smooth_scrolling,
              show_dismiss_button: guides_settings.show_dismiss_button,
              show_back_button: guides_settings.show_back_button,
              show_main_button: guides_settings.show_main_button,
              main_button_text: guides_settings.main_button_text,
              dim_by_default: guides_settings.dim_by_default,
              dim_style: guides_settings.dim_style,
              celebrate_guides_completion: guides_settings.celebrate_guides_completion,
              show_avatar: guides_settings.show_avatar,
              avatar_url: guides_settings.avatar_url,
              avatar_title: guides_settings.avatar_title,
              fab: guides_settings.fab
            }
          }
          |> Repo.insert!()

        {:ok, demo_version_settings}
    end
  end

  @doc """
  Gets storyline settings.

  ## Examples

      iex> get_storyline_settings(storyline_id)
      %StorylineSettings{}
  """
  def get_storyline_settings(storyline_id) do
    [Storylines.get_storyline!(storyline_id)]
    |> get_many_storyline_settings()
    |> Map.get(storyline_id)
  end

  @doc """
  Create default settings for the storyline.

  ## Examples

      iex> create_storyline_settings(storyline_id)
      {:ok, %StorylineSettings{}}

      iex> create_storyline_settings(storyline_id)
      {:error, "Settings already exists"}

  """
  def create_storyline_settings(storyline_id, attrs \\ %{}) do
    case fetch_nullable_storyline_settings(storyline_id) do
      {:error, :not_found} ->
        %StorylineSettings{
          storyline_id: storyline_id,
          guides_settings: %StorylineGuidesSettings{}
        }
        |> StorylineSettings.create_changeset(attrs)
        |> Repo.insert()

      {:ok, _} ->
        {:error, "Settings already exist"}
    end
  end

  @doc """
  get storyline settings for many storylines batched in a single query

  ## Examples

      iex> get_many_storyline_settings([%Storyline{}])
      {:ok, %{"<id>" => %StorylineSettings{}}}
  """
  def get_many_storyline_settings(storylines) do
    storylines =
      Repo.preload(storylines,
        settings: [:guides_settings],
        company: [settings: [:guides_settings]]
      )

    storylines
    |> Enum.map(&{&1.id, StorylineSettings.cascade(&1.settings, &1.company.settings)})
    |> Enum.into(%{})
  end

  @doc """
  fetch nullable (or uncascaded) storyline settings. This are the settings without the null fields
  filled (cascaded) with the company defaults.

  ## Examples

      iex> fetch_nullable_storyline_settings("<id>")
      {:ok, %StorylineSettings{}}

      iex> fetch_nullable_storyline_settings("<non existent id>")
      {:ok, :not_found}
  """
  def fetch_nullable_storyline_settings(storyline_id),
    do: Repo.fetch_by(StorylineSettings, storyline_id: storyline_id)

  @doc """
  Updates the storyline's settings with the passed attributes.

  ## Examples

      iex> update_storyline_settings(%StorylineSettings{}, %{main_color: "#123456", secondary_color: "#abcdef"})
      {:ok, %StorylineSettings{main_color: "#123456", secondary_color: "#abcdef"}}

      iex> update_storyline_settings(%StorylineSettings{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_storyline_settings(%StorylineSettings{} = current_settings, attrs, actor) do
    current_settings = current_settings |> Repo.preload(storyline: [])

    with :ok <- Api.Authorizer.authorize(current_settings.storyline, actor, :presenter) do
      update_storyline_settings_unauthorized(current_settings, attrs)
    end
  end

  def update_storyline_settings(storyline_id, attrs, actor) when is_binary(storyline_id) do
    with {:ok, storyline_settings} <- fetch_nullable_storyline_settings(storyline_id) do
      update_storyline_settings(storyline_settings, attrs, actor)
    end
  end

  def update_storyline_settings_unauthorized(%StorylineSettings{} = current_settings, attrs) do
    Repo.preload(current_settings, :guides_settings)
    |> StorylineSettings.update_changeset(attrs)
    |> Repo.update()
  end

  def update_storyline_settings_unauthorized(storyline_id, attrs) when is_binary(storyline_id) do
    with {:ok, storyline_settings} <- fetch_nullable_storyline_settings(storyline_id) do
      update_storyline_settings_unauthorized(storyline_settings, attrs)
    end
  end
end
