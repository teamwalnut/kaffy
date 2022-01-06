defmodule Api.Storylines.Editing.Edit.Link do
  @moduledoc false
  alias __MODULE__.{ScreenDestination, UrlDestination}

  import PolymorphicEmbed, only: [cast_polymorphic_embed: 2]

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive {Jason.Encoder, only: [:destination, :target_screen_id]}
  embedded_schema do
    field(:destination, PolymorphicEmbed,
      types: [
        screen: ScreenDestination,
        url: UrlDestination
      ],
      type_field: "kind",
      on_replace: :update,
      on_type_not_found: :raise
    )

    field(:target_screen_id, :string, deprecate: true)

    belongs_to(:target_screen, Api.Storylines.Screen,
      foreign_key: :target_screen_id,
      references: :id,
      define_field: false
    )
  end

  def destination(link) do
    case link.target_screen_id do
      nil ->
        link.destination

      _ ->
        if link.destination == nil do
          %ScreenDestination{
            kind: "screen",
            id: link.target_screen_id
          }
        else
          %ScreenDestination{
            kind: "screen",
            id: link.target_screen_id,
            delay_ms: link.destination.delay_ms
          }
        end
    end
  end

  def changeset(schema, attrs) do
    attrs = get_attributes_for_changeset(attrs)

    schema
    |> cast(attrs, [:target_screen_id])
    |> cast_polymorphic_embed(:destination)
    |> validate_required([:destination])
  end

  defp get_attributes_for_changeset(attrs) do
    # note(nadav): We want to make sure, that for now, we create both the
    # old format `target_screen_id` and the new format `destination`
    target_screen_id =
      case attrs do
        %{target_screen_id: target_screen_id} when target_screen_id != nil -> target_screen_id
        _ -> nil
      end

    if target_screen_id == nil do
      id =
        case attrs do
          %{destination: %{id: id}} when id != nil -> id
          _ -> nil
        end

      if id != nil do
        Map.put(attrs, :target_screen_id, id)
      else
        attrs
      end
    else
      Map.merge(attrs, %{
        target_screen_id: target_screen_id,
        destination: %{kind: "screen", id: target_screen_id}
      })
    end
  end
end
