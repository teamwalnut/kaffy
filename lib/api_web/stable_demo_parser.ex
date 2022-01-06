defmodule ApiWeb.StableDemoParser do
  @moduledoc """
  Parses a given demo grapqhl query result to %Api.Storylines.Demos.StableDemoData{}
  """
  alias Api.Storylines.Demos.StableDemoData

  @doc """
  Intercepts every request right before sending them and checks if they're a
  demo graphql query request, and generate static assets for the demo:

  - Update latest demo version for the lambda
  - Upload the static demo data to S3
  - Copy the index.html for the lambda
  """
  def absinthe_before_send(conn, blueprint) do
    if is_demo_query?(blueprint) do
      {:ok, stable_demo_data} = from_graphql_blueprint(blueprint)

      spawn(fn ->
        :ok =
          StableDemoData.update_latest_demo_version(
            stable_demo_data.demo_id,
            stable_demo_data.demo_version_id
          )
      end)

      spawn(fn ->
        :ok = StableDemoData.upload_to_s3(stable_demo_data)
      end)

      spawn(fn ->
        StableDemoData.copy_index_html(stable_demo_data.demo_version_id)
      end)
    end

    conn
  end

  defp from_graphql_blueprint(blueprint) do
    query_string = blueprint.source
    result = blueprint.result

    {:ok,
     %Api.Storylines.Demos.StableDemoData{
       demo_id: result.data["demo"]["id"],
       demo_version_id: result.data["demo"]["activeVersion"]["id"],
       demo_data: result,
       demo_hash: :crypto.hash(:sha256, query_string) |> Base.encode64()
     }}
  end

  defp is_demo_query?(blueprint) do
    query_name(blueprint.input.definitions) == "demo"
  end

  defp query_name([
         %Absinthe.Language.OperationDefinition{
           selection_set: %Absinthe.Language.SelectionSet{
             selections: [
               %Absinthe.Language.Field{
                 name: name
               }
               | _
             ]
           }
         }
         | _
       ]) do
    name
  end
end
