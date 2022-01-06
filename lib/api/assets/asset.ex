defmodule Api.Assets.Asset do
  @moduledoc false
  use Api.Schema

  @primary_key false
  schema "assets" do
    field :name, :string
    timestamps()
  end

  def create_changeset(asset, attrs) do
    asset
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> remove_hash
    |> unsafe_validate_unique([:name], Api.Repo)
    |> unique_constraint([:name], name: :assets_name_index)
  end

  defp remove_hash(changeset) do
    name_without_hash =
      get_field(changeset, :name)
      |> URI.parse()
      |> Map.put(:fragment, nil)
      |> URI.to_string()

    update_change(changeset, :name, fn _ -> name_without_hash end)
  end

  def by_uris_query(uris) do
    from asset in __MODULE__,
      where: asset.name in ^uris
  end
end
