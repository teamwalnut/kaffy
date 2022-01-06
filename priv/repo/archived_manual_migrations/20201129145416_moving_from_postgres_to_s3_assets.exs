defmodule Api.Repo.ManualMigrations.MovingFromPostgresToS3Assets do
  use Ecto.Migration
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  def up do
    Enum.each([:ex_aws, :ex_aws_s3, :mojito], &Application.ensure_all_started/1)

    Api.Repo.all(screens_with_companies())
    |> Enum.map(fn screen ->
      %{
        id: screen.id,
        data: screen.screenshot_image_uri,
        company_id: screen.storyline.company.id,
        uuid: Ecto.UUID.generate()
      }
    end)
    |> Enum.filter(&is_data_uri?/1)
    |> Task.async_stream(&upload_to_s3/1, max_concurrency: 10, timeout: 60_000)
    |> Stream.map(&update_screen/1)
    |> Stream.run()
  end

  def down do
    :ok
  end

  defp is_data_uri?(%{data: data}) do
    data |> String.starts_with?("data:")
  end

  defp upload_to_s3(%{id: id, data: data, company_id: company_id, uuid: uuid}) do
    data = data |> String.split(",") |> Enum.at(1) |> Base.decode64!()

    mediatype = "image/jpeg"
    bucket = bucket_name()

    resp =
      ExAws.S3.put_object(bucket, "#{company_id}/#{uuid}", data, [
        {:content_type, mediatype}
      ])
      |> ExAws.request!()

    case resp do
      {:error, err} ->
        {:error, err}

      %{body: _, status_code: 200} ->
        %{bucket: bucket, id: id, company_id: company_id, uuid: uuid}
    end
  end

  defp update_screen({:ok, %{bucket: bucket, id: id, company_id: company_id, uuid: uuid}}) do
    change(%Api.Storylines.Screen{id: id}, screenshot_image_uri: to_full_url(company_id, uuid))
    |> Api.Repo.update!()
  end

  defp screens_with_companies do
    from screen in Api.Storylines.Screen,
      preload: [storyline: [:company]]
  end

  defp bucket_name do
    Application.get_env(:api, :s3)[:bucket_name]
  end

  defp to_full_url(company_id, uuid) do
    "https://app.teamwalnut.com/assets/api/assets?name=#{company_id}/#{uuid}"
  end
end
