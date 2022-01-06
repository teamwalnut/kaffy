defmodule Api.Patching.HtmlPatch do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :position, Ecto.Enum, values: [:append_child, :append_script_tag]
    field :css_selector, :string
    field :html, :string
    field :target_url_glob
  end

  def changeset(html_patch, params) do
    html_patch
    |> cast(params, [:position, :css_selector, :html, :target_url_glob])
    |> validate_required([:position, :css_selector, :html])
  end
end
