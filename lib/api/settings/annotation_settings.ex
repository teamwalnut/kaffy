defmodule Api.Settings.AnnotationSettings do
  @moduledoc """
  These are the settings for a specific annotation.
  The difference with `Api.Settings.GuideSettings` is that in this schema null values are allowed
  """

  use Api.EmbededSchema

  @derive {Jason.Encoder,
           except: [
             :__struct__
           ]}

  embedded_schema do
    field(:show_main_button, :boolean)
    field(:main_button_text, :string)
    field(:show_dismiss_button, :boolean)
    field(:show_back_button, :boolean)
    field(:show_avatar, :boolean)
    field(:avatar_url, :string)
    field(:avatar_title, :string)
    field(:show_dim, :boolean)
    field(:size, Ecto.Enum, values: [:small, :medium, :large])
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [
      :show_main_button,
      :main_button_text,
      :show_dismiss_button,
      :show_back_button,
      :show_avatar,
      :avatar_url,
      :avatar_title,
      :show_dim,
      :size
    ])
  end
end
