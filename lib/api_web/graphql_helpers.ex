defmodule ApiWeb.GraphQLHelpers do
  @moduledoc false

  # Since GraphQL does not support union type in inputs,
  # we need to translate from the input object structure to our domain structure
  # For example
  # `link_edit_props: {toScreen: {id: "123"}}` will become
  # `link_edit_props: {destination: {type: "screen", id: "123"}}`
  def translate_mutation_polymorphism_of_edits(edits),
    do: edits |> Enum.map(&transtranslate_mutation_polymorphism_of_edit(&1))

  defp transtranslate_mutation_polymorphism_of_edit(edit) do
    case edit.kind do
      :link ->
        %{edit | link_edit_props: link_props_translation(edit.link_edit_props)}

      _ ->
        edit
    end
  end

  defp link_props_translation(%{target_screen_id: target_screen_id}),
    do: %{destination: %{kind: "screen", id: target_screen_id}}

  defp link_props_translation(%{to_screen: to_screen}),
    do: %{destination: Map.put_new(to_screen, :kind, "screen")}

  defp link_props_translation(%{to_url: to_url}),
    do: %{destination: Map.put_new(to_url, :kind, "url")}
end
